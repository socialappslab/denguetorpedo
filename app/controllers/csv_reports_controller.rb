#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login
  after_filter :calculate_time_series_for_visits, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")

    @visits              = @csv_reports.includes(:location).map {|r| r.location}.compact.uniq
    @total_locations     = @visits.count
  end


  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/new

  def new
    @csv_report = CsvReport.new
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/1/csv_reports

  # We assume the user will upload a specific CSV (or .xls, .xlsx) template.
  # Once uploaded, we parse the CSV and assign a UUID to each row which
  # will be saved with a new report (if it's ever created).
  # If a report exists with the UUID, then we update that report instead of
  # creating a new one.
  def create

    # 1. Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_location")
      render "new" and return
    end

    # 2. Identify the file content type.
    file        = params[:csv_report][:csv]
    spreadsheet = CsvReport.load_spreadsheet( file )
    unless spreadsheet
      flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_format")
      render "new" and return
    end

    # 3. Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = CsvReport.extract_address_from_spreadsheet(spreadsheet)
    if address.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_house")
      render "new" and return
    end



    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = CsvReport.extract_header_from_spreadsheet(spreadsheet)


    # 4. Parse the CSV.
    # The CSV is laid out to define the house number (or address)
    # on the first row, and then the following template for the table:
    # [
    #   "fecha de visita (aaaa-mm-dd)",
    #   "tipo de criadero",
    #   "localización",
    #   "protegido",
    #   "abatizado",
    #   "larvas",
    #   "pupas",
    #   "foto de criadero",
    #   "eliminado (aaaa-mm-dd)",
    #   "foto de eliminación",
    #   "comentarios sobre tipo y/o eliminación*"
    # ]

    # 5. Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_visits")
      render "new" and return
    end

    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    rows.each do |row|
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      type = row_content[:breeding_site].strip.downcase
      if CsvReport.accepted_breeding_site_codes.exclude?(type)
        flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_code")
        render "new" and return
      end
    end

    # At this point, we have a non-trivial CSV with valid breeding codes.
    reports            = []
    visits             = []
    current_visited_at = nil

    rows.each_with_index do |row, row_index|
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      # Build report attributes.
      uuid        = CsvReport.generate_uuid_from_row_index_and_address(row, row_index, address)
      description = CsvReport.generate_description_from_row_content(row_content)

      type = row_content[:breeding_site].strip.downcase
      if type == "a"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type == "b"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
      elsif type == "l"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
      elsif type == "m"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type == "p"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
      elsif type == "t"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
      end

      # Add to reports only if the code doesn't equal "negative" code.
      unless type == "n"
        reports << {
          :visited_at    => row_content[:visited_at],
          :eliminated_at => row_content[:eliminated_at],
          :breeding_site => breeding_site,
          :description   => description,
          :protected     => row_content[:protected],
          :chemically_treated => row_content[:chemical],
          :larvae => row_content[:larvae],
          :pupae => row_content[:pupae],
          :csv_uuid => uuid
        }
      end

      # Finally, let's add a visit if it's a new visit.
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at = row_content[:visited_at]
        disease_report     = row_content[:health_report]

        # Now let's see if the location is clean.
        # If the last type is n, then the location is clean (for now).
        # If it's not the last row, then we simply label the status as a potential
        # breeding site. The actual status will be updated when the associated
        # report for the location is updated.
        if row_index.to_i == spreadsheet.last_row.to_i && type && type.strip.downcase == "n"
          status = Visit::Cleaning::NEGATIVE
        else
          status = Visit::Cleaning::POTENTIAL
        end

        # Now let's try parsing the date.
        visit_date = Time.zone.parse(row_content[:visited_at])
        visit_date = Time.now if visit_date.blank?

        visits << {
          :visited_at => visit_date,
          :health_report => disease_report,
          :status => status
        }

      end
    end

    # 6. Find and/or create the location.
    location = Location.find_by_address(address)
    if location.blank?
      location = Location.create!(:latitude => lat, :longitude => long, :address => address)
    end

    # Now that we have a location, let's update the visit.
    # Note that if the reports that will be reported after this have any
    # positive status, then the location will be treated updated accordingly.
    # NOTE: The reports will be associated with these visits thanks to the report's
    # callback hook.
    visits.each do |visit|
      ls = Visit.where(:location_id => location.id)
      ls = ls.where(:visited_at => (visit[:visited_at].beginning_of_day..visit[:visited_at].end_of_day) ).order("visited_at DESC")
      if ls.blank?
        ls = Visit.new(:location_id => location.id)
        ls.visited_at = visit[:visited_at]
      else
        ls = ls.first
      end

      ls.identification_type  = visit[:status]
      ls.health_report        = visit[:health_report]
      ls.save
    end


    # 7. Create or update the CSV file.
    # TODO: For now, we simply create a new CSV file everytime it's uploaded.
    # In the future, we want to search out CSV reports to see if any/all report
    # UUID match those that were parsed here.
    @csv_report = CsvReport.find_by_parsed_content(rows.to_json)
    if @csv_report.blank?
      @csv_report                = CsvReport.new
      @csv_report.csv            = file
      @csv_report.parsed_content = rows.to_json
      @csv_report.user_id        = @current_user.id
      @csv_report.location_id    = location.id
      @csv_report.save!
    end

    Analytics.track( :user_id => @current_user.id, :event => "Created a CSV report") if Rails.env.production?

    # 8. Create or update the reports.
    # NOTE: We set completed_at to nil in order to signify that the user
    # has to update the report.
    reports.each do |report|
      r = Report.find_by_csv_uuid(report[:csv_uuid])
      if r.blank?
        r = Report.new

        # Note: We're overriding the created_at and updated_at dates in order
        # to more closely reflect the correct site identification time.
        # Also, note that we *must* set updated_at to same as created_at in order
        # for the set_location_status method to correctly update the Visit
        # instance to the right date (which is the date of house inspection).
        parsed_inspection_date = Time.zone.parse( report[:visited_at] )
        if parsed_inspection_date.blank?
          puts "\n\n\n [Error] Could not parse inspection date = #{report[:visited_at]}...\n\n\n"
        else
          r.created_at = parsed_inspection_date
          r.updated_at = parsed_inspection_date
        end

        Analytics.track( :user_id => @current_user.id, :event => "Created a new report", :properties => {:source => "CSV"}) if Rails.env.production?
      end


      # Note: We're overriding the eliminated_at column in order to allow
      # Nicaraguan community members to have more control over their reports.
      elimination_date = Time.zone.parse( report[:eliminated_at] )
      if elimination_date.blank?
        puts "\n\n\n [Error] Could not parse elimination date = #{report[:eliminated_at]}...\n\n\n"
      else
        r.eliminated_at = elimination_date
      end

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
      r.save(:validate => false)
    end

    # At this point, let's celebrate.
    flash[:notice] = I18n.t("views.csv_reports.flashes.create")
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------


  private



  #----------------------------------------------------------------------------

end
