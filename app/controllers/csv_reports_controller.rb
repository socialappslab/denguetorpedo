#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login
  before_filter :calculate_ivars,                  :only => [:index]
  before_filter :calculate_time_series_for_visits, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
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
    @csv_report = CsvReport.new

    # Ensure that the location has been identified on the map.
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

    # Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_visits")
      render "new" and return
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
      if CsvReport.accepted_breeding_site_codes.exclude?(type)
        flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_code")
        render "new" and return
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
        parsed_current_visited_at = Time.zone.parse( current_visited_at ) || Time.now

        if parsed_current_visited_at.future?
          flash[:alert] = I18n.t("views.csv_reports.flashes.inspection_date_in_future")
          render "new" and return
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
        eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

        # If the date of elimination is in the future or before visit date, then let's raise an error.
        if eliminated_at.present? && eliminated_at.future?
          flash[:alert] = I18n.t("views.csv_reports.flashes.elimination_date_in_future")
          render "new" and return
        end

        if eliminated_at.present? && eliminated_at < parsed_current_visited_at
          flash[:alert] = I18n.t("views.csv_reports.flashes.elimination_date_before_inspection_date")
          render "new" and return
        end

        reports << {
          :visited_at    => parsed_current_visited_at,
          :eliminated_at => eliminated_at,
          :breeding_site => breeding_site,
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
      location = Location.create!(:latitude => lat, :longitude => long, :address => address)
    end


    #-------------------------------
    # Create or update the CSV file.
    @csv_report = CsvReport.find_by_parsed_content(rows.to_json)
    if @csv_report.blank?
      @csv_report                = CsvReport.new
      @csv_report.csv            = file
      @csv_report.parsed_content = rows.to_json
      @csv_report.user_id        = @current_user.id
      @csv_report.location_id    = location.id
      @csv_report.save

      Analytics.track( :user_id => @current_user.id, :event => "Created a CSV report") if Rails.env.production?
    end


    #------------------------------
    # Create or update the reports.
    reports.each do |report|
      r = Report.find_by_csv_uuid(report[:csv_uuid])
      if r.blank?
        r            = Report.new
        r.created_at = report[:visited_at] if report[:visited_at].present?
        Analytics.track( :user_id => @current_user.id, :event => "Created a new report", :properties => {:source => "CSV"}) if Rails.env.production?
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
      r.eliminated_at      = report[:eliminated_at]
      r.save(:validate => false)
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

    #-------------------------------
    # At this point, let's celebrate.
    flash[:notice] = I18n.t("views.csv_reports.flashes.create")
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def calculate_ivars
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")
    @visit_ids   = @csv_reports.includes(:location).map {|r| r.location}.compact.uniq
  end

  #----------------------------------------------------------------------------

end
