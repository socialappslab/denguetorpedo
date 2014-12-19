#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")

    @visits              = @csv_reports.includes(:location).map {|r| r.location}.compact.uniq
    @total_locations     = @visits.count
    @statistics = LocationStatus.calculate_time_series_for_locations(@visits)
    @table_statistics = @statistics.last
    @chart_statistics = @statistics.map {|hash|
      [
        hash[:date],
        hash[:positive][:percent],
        hash[:potential][:percent],
        hash[:negative][:percent],
        hash[:clean][:percent]
      ]
    }

    @newest_status_distribution = @statistics.last
    if @newest_status_distribution.present?
      @positive_locations  = @newest_status_distribution[:positive][:count]
      @potential_locations = @newest_status_distribution[:potential][:count]
      @negative_locations  = @newest_status_distribution[:negative][:count]
      @clean_locations     = @newest_status_distribution[:clean][:count]
    else
      @positive_locations  = 0
      @potential_locations = 0
      @negative_locations  = 0
      @clean_locations     = 0
    end




    @statistics = LocationStatus.calculate_time_series_for_locations(@visits)
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

    # 1. Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_location")
      render "new" and return
    end

    # 2. Identify the file content type.
    file        = params[:csv_report][:csv]
    spreadsheet = load_spreadsheet( file )
    unless spreadsheet
      flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_format")
      render "new" and return
    end

    # 3. Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    address = spreadsheet.row(1)[1]
    if address.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_house")
      render "new" and return
    end
    address = address.to_s


    start_index = 2
    while spreadsheet.row(start_index)[0].blank?
      start_index += 1
    end
    header  = spreadsheet.row(start_index)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }


    reports        = []
    parsed_content = []

    # NOTE: We assume the location is not clean unless otherwise noted.
    is_location_clean = false

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
    current_row = 0
    (start_index + 1..spreadsheet.last_row).each do |i|
      row            = Hash[[header, spreadsheet.row(i)].transpose]
      parsed_content << row
      current_row   += 1

      # 4a. Extract the attributes. NOTE: We use fuzzy matching instead of
      # exact matching since users may vary the columns slightly.
      date           = row.select {|k,v| k.include?("fecha")}.values[0].to_s
      room           = row["localización"].to_s
      type           = row.select {|k,v| k.include?("tipo")}.values[0].to_s
      is_protected   = row['protegido'].to_i
      is_pupas       = row["pupas"].to_i
      is_larvas      = row["larvas"].to_i
      is_chemical     = row["abatizado"].to_i
      elim_date      = row.select {|k,v| k.include?("eliminado")}.values[0].to_s
      comments       = row.select {|k,v| k.include?("comentarios")}.values[0].to_s



      # 4b. Attempt to identify the breeding sites from the codes. If no type
      # is identified, then simply skip the whole row.
      next if type.blank?

      type = type.strip.downcase
      if ["a", "b", "l", "m", "p", "t", "x", "v"].include?( type )
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
      else
        flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_code")
        render "new" and return
      end

      # 4c. Define the description based on the collected attributes.
      description  = "Fecha de visita: #{date}"
      description += ", Localización: #{room} (#{address})" if room.present?
      description += ", Protegido: #{is_protected}, Abatizado: #{is_chemical}, Larvas: #{is_larvas}, Pupas: #{is_pupas}"
      description += ", Eliminado: #{elim_date}" if elim_date.present?
      description += ", Comentarios sobre tipo y/o eliminación: #{comments}" if comments.present?

      # 4d. Generate a UUID to identify the row that the report will correspond
      # to. We define the UUID based on
      # * House location,
      # * Date of visit,
      # * The room within the house,
      # * Type of site,
      # * Properties identified at the site.
      # If there is a match, then we simply update the existing report.
      uuid = (address + date + room + type + is_protected.to_s + is_pupas.to_s + is_larvas.to_s + is_chemical.to_s)
      uuid = uuid.strip.downcase.underscore

      if type && type.strip.downcase != "v"
        reports << {
          :inspection_date  => date,
          :elimination_date => elim_date,
          :breeding_site => breeding_site,
          :description => description,
          :protected => is_protected, :chemically_treated => is_chemical, :larvae => is_larvas, :pupae => is_pupas,
          :csv_uuid => uuid}
      end

      # If the last type is v, then the location is clean (for now).
      if i.to_i == spreadsheet.last_row.to_i && type && type.strip.downcase == "v"
        is_location_clean = true
      end
    end

    # 5. Error out if there are no reports extracted.
    if current_row == 0
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_visits")
      render "new" and return
    end

    # 6. Find and/or create the location.
    location = Location.find_by_address(address)
    if location.blank?
      location = Location.create!(:latitude => lat, :longitude => long, :address => address)
    end
    location.update_column(:cleaned, is_location_clean)

    # 7. Create or update the CSV file.
    # TODO: For now, we simply create a new CSV file everytime it's uploaded.
    # In the future, we want to search out CSV reports to see if any/all report
    # UUID match those that were parsed here.
    @csv_report.csv            = file
    @csv_report.parsed_content = parsed_content.to_json
    @csv_report.user_id        = @current_user.id
    @csv_report.location_id    = location.id
    @csv_report.save!

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
        # for the set_location_status method to correctly update the LocationStatus
        # instance to the right date (which is the date of house inspection).
        begin
          r.created_at = DateTime.parse( report[:inspection_date] )
          r.updated_at = DateTime.parse( report[:inspection_date] )
        rescue
        end

        Analytics.track( :user_id => @current_user.id, :event => "Created a new report", :properties => {:source => "CSV"}) if Rails.env.production?
      end

      # Note: We're overriding the eliminated_at column in order to allow
      # Nicaraguan community members to have more control over their reports.
      begin
        r.eliminated_at = DateTime.parse( report[:elimination_date] )
      rescue
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

  def load_spreadsheet(file)
    if File.extname( file.original_filename ) == ".csv"
      spreadsheet = Roo::CSV.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xls"
      spreadsheet = Roo::Excel.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file.tempfile.path, :file_warning => :ignore)
    end

    return spreadsheet
  end

  #----------------------------------------------------------------------------

end
