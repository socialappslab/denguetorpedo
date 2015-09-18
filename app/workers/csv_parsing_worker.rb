require "sidekiq"

class CsvParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform(csv_id, params)
    lat  = params["report_location_attributes_latitude"]
    long = params["report_location_attributes_longitude"]

    @neighborhood = Neighborhood.find(params["neighborhood_id"])
    @csv_report   = CsvReport.find_by_id(csv_id)
    return if @csv_report.blank?

    # Identify the file content type.
    spreadsheet = CsvReport.load_spreadsheet( @csv_report.csv )
    unless spreadsheet
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::UNKNOWN_FORMAT)
      return
    end

    # Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = CsvReport.extract_address_from_spreadsheet(spreadsheet)
    if address.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_HOUSE)
      return
    end

    # Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_VISITS)
      return
    end

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = CsvReport.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    @csv_report.check_for_breeding_site_errors(rows)

    # Iterate over the rows, checking if any dates are invalid.
    @csv_report.check_for_date_errors(rows)

    # If there are any errors, we can't proceed so let's offload right now and let
    # the user re-upload when they've fixed the errors.
    return if @csv_report.csv_errors.present?

    # Find and/or create the location and assign it to the report.
    location = Location.find_by_address(address)
    location = Location.create!(:latitude => lat, :longitude => long, :address => address, :neighborhood_id => @neighborhood.id) if location.blank?
    @csv_report.parsed_content = rows.to_json
    @csv_report.location_id    = location.id

    #--------------------------------------------------------------------------
    # Let's iterate over the rows and create/update reports.
    #------

    # At this point, we do not have any errors. Let's iterate over each row, and
    # create/update the reports accordingly.
    reports            = []
    visits             = []
    current_visited_at = nil
    parsed_current_visited_at = nil
    rows.each_with_index do |row, row_index|
      row_content = CsvReport.extract_content_from_row(row)

      # Let's begin by creating a visit, if applicable.
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        parsed_current_visited_at = Time.zone.parse( row_content[:visited_at] )

        ls = Visit.where(:location_id => location.id)
        ls = ls.where(:parent_visit_id => nil)
        ls = ls.where(:visited_at => (parsed_current_visited_at.beginning_of_day..parsed_current_visited_at.end_of_day))
        ls = ls.order("visited_at DESC").first
        if ls.blank?
          ls                 = Visit.new
          ls.parent_visit_id = nil
          ls.location_id     = location.id
          ls.visited_at      = parsed_current_visited_at
        end

        ls.health_report = row_content[:health_report]
        ls.save
      end

      # The specific bug here was that a valid visit date was completely ignored
      # because the row didn't have a breeding site. The correct solution is to
      # parse and store the visit date, and then make a decision on whether to
      # continue parsing the remaining columns.
      next if row_content[:breeding_site].blank?

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
      r.reporter_id        = @csv_report.user_id
      r.csv_report_id      = @csv_report.id
      r.csv_uuid           = report[:csv_uuid]
      r.eliminated_at      = report[:eliminated_at]
      r.save(:validate => false)

      if new_report == true
        v = r.find_or_create_first_visit()
        r.update_inspection_for_visit(v)
      end

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

        r.update_inspection_for_visit(v)
      end
    end


    @csv_report.parsed_at      = Time.zone.now
    @csv_report.save
  end
end
