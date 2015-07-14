require "sidekiq"

class CsvParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform(csv_id)
    @csv_report = CsvReport.find_by_id(csv_id)
    return if @csv.blank?

    # 3. Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = CsvReport.extract_address_from_spreadsheet(spreadsheet)
    if address.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_HOUSE)
    end

    # Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_VISITS)
    end

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = CsvReport.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    rows.each do |row|
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      type = row_content[:breeding_site].strip.downcase
      if CsvReport.accepted_breeding_site_codes.exclude?(type[0])
        CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::UNKNOWN_CODE)
      end
    end


    #-------------------------------------------------------------------
    # At this point, we have a non-trivial CSV with valid breeding codes.
    reports            = []
    visits             = []
    current_visited_at = nil
    parsed_current_visited_at = nil
    rows.each_with_index do |row, row_index|
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      # Let's begin by creating a visit, if applicable.
      # Let's parse the current visited at date.
      # NOTE: If the last type is N then the location is clean (definition). However,
      # we don't have to keep track of it in some "status" key. Why? Because the visit
      # will have 0 reports, which is taken into account in visit.identification_type
      # method!
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at        = row_content[:visited_at]
        parsed_current_visited_at = Time.zone.parse( current_visited_at ) || Time.zone.now

        if parsed_current_visited_at.future?
          CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::VISIT_DATE_IN_FUTURE)
        end

        visits << {
          :visited_at    => parsed_current_visited_at,
          :health_report => row_content[:health_report]
        }
      end


      # Build report attributes.
      uuid        = CsvReport.generate_uuid_from_row_index_and_address(row, row_index, address)
      description = CsvReport.generate_description_from_row_content(row_content)

      type = row_content[:breeding_site].strip.downcase
      if type.include?("a")
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type.include?("b")
        breeding_site = BreedingSite.find_by_code("B")
      elsif type.include?("l")
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
      elsif type.include?("m")
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type.include?("p")
        breeding_site = BreedingSite.find_by_code("P")
      elsif type.include?("t")
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
      end

      # We say that the report has a field identifier if the breeding site CSV column
      # also has an integer associated with it.
      field_identifier = nil
      field_identifier = type if type =~ /\d/

      # Add to reports only if the code doesn't equal "negative" code.
      unless type == "n"
        eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

        # If the date of elimination is in the future or before visit date, then let's raise an error.
        if eliminated_at.present? && eliminated_at.future?
          CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::ELIMINATION_DATE_IN_FUTURE)
        end

        if eliminated_at.present? && eliminated_at < parsed_current_visited_at
          CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE)
        end

        reports << {
          :visited_at    => parsed_current_visited_at,
          :eliminated_at => eliminated_at,
          :breeding_site => breeding_site,
          :field_identifier => field_identifier,
          :description   => description,
          :protected     => row_content[:protected],
          :chemically_treated => row_content[:chemical],
          :larvae => row_content[:larvae],
          :pupae => row_content[:pupae],
          :csv_uuid => uuid
        }
      end
    end

    #--------------------------------
    # Find and/or create the location.
    location = Location.find_by_address(address)
    if location.blank?
      location = Location.create!(:latitude => lat, :longitude => long, :address => address, :neighborhood_id => @neighborhood.id)
    end

    #-------------------------------
    # Create or update the CSV file.

    existing_report = CsvReport.find_by_parsed_content(rows.to_json)
    if existing_report.blank?
      @csv_report.parsed_content = rows.to_json
      @csv_report.location       = location.id
      @csv_report.parsed_at      = Time.zone.now
    else
      @csv_report = existing_report
    end


    #------------------------------
    # Create or update the reports
    # We create a new report if the following is true:
    # * It's a new visit AND
    # * The "breeding site" column has an identifier (e.g. B3) different
    #   than any previous report.
    reports.each do |report|
      # TODO: Horrible way of checking whether we have a new report and thereby
      # creating Visit instance.
      new_report = false
      already_exists_report = nil
      r = Report.find_by_field_identifier(report[:field_identifier]) if report[:field_identifier].present?

      # TODO: Refactor this cluster fuck.
      if r.blank?
        already_exists_report = Report.find_by_csv_uuid(report[:csv_uuid])
        if already_exists_report.present?
          r = already_exists_report
        else
          new_report   = true
          r            = Report.new
          r.field_identifier = report[:field_identifier]
          r.created_at = report[:visited_at] if report[:visited_at].present?
          # Analytics.track( :user_id => @current_user.id, :event => "Created a new report", :properties => {:source => "CSV"}) if Rails.env.production?
        end
      end

      # Let's update the report and save.
      r.report             = report[:description]
      r.breeding_site_id   = report[:breeding_site].id if report[:breeding_site].present?
      r.protected          = report[:protected]
      r.chemically_treated = report[:chemically_treated]
      r.larvae             = report[:larvae]
      r.pupae              = report[:pupae]
      r.location_id        = location.id
      r.neighborhood_id    = @neighborhood.id
      r.reporter_id        = @current_user.id
      r.csv_report_id      = @csv_report.id
      r.csv_uuid           = report[:csv_uuid]
      r.eliminated_at      = report[:eliminated_at]
      r.save(:validate => false)

      # We create an inspection for this report if we know the report to be present,
      # and it's not eliminated yet.
      if new_report == false && already_exists_report.blank? && report[:eliminated_at].blank?
        v = Visit.where(:location_id => location.id)
        v = v.where("parent_visit_id IS NOT NULL")
        v = v.where(:visited_at => (report[:visited_at].beginning_of_day..report[:visited_at].end_of_day))
        v = v.order("visited_at DESC").limit(1)
        if v.blank?
          v                 = Visit.new
          v.location_id     = location.id
          v.parent_visit_id = r.initial_visit.id if r.initial_visit.present? # TODO: We're not really using this column I think.
          v.visited_at      = report[:visited_at]
          v.save
        else
          v = v.first
        end

        ins = Inspection.find_by_visit_id_and_report_id(v.id, r.id)
        ins = Inspection.new(:visit_id => v.id, :report_id => r.id) if ins.blank?
        ins.identification_type = r.status
        ins.save
      end
    end

    #--------------------------------------------------------------------
    # The above Report callbacks create a set of visits and inspections. Here, we iterate
    # over our own set of visits, and either
    #
    # a) find existing visit with same date and set the health report,
    # b) create new visit (e.g. if it's of code N with no associated reports)
    #
    # We *must* run this here just so we can let the callbacks do their job.
    visits.each do |visit|
      parsed_visited_at = visit[:visited_at]

      ls = Visit.where(:location_id => location.id)
      ls = ls.where(:parent_visit_id => nil)
      ls = ls.where(:visited_at => (parsed_visited_at.beginning_of_day..parsed_visited_at.end_of_day))
      ls = ls.order("visited_at DESC").limit(1)
      if ls.blank?
        ls                 = Visit.new
        ls.parent_visit_id = nil
        ls.location_id     = location.id
        ls.visited_at      = parsed_visited_at
      else
        ls = ls.first
      end

      ls.health_report = visit[:health_report]
      ls.save
    end

    incomplete_reports = @current_user.incomplete_reports
    if incomplete_reports.present?
      report = incomplete_reports.first
      notice = I18n.t("views.reports.flashes.call_to_action_to_complete")
      redirect_path = edit_neighborhood_report_path(@neighborhood, report)
    else
      notice = I18n.t("activerecord.success.report.create")
      redirect_path = neighborhood_reports_path(@neighborhood)
    end

  end
end
