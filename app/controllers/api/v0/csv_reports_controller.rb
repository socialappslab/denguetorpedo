# -*- encoding : utf-8 -*-

class API::V0::CsvReportsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user
  before_filter :identify_csv, :only => [:update, :verify]
  before_filter :set_locale

  @logger = Rails.logger

  #----------------------------------------------------------------------------
  # POST /api/v0/csv_reports

  # We assume the user will upload a particular CSV only once. This means that
  # a 'rolling update' to any CSV will be treated as different CSVs.
  def create
    # Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.missing_location"), 422) and return
    end

    if params[:spreadsheet].blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422) and return
    end

    # Find the neighborhood.
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])

    # Create or find the location.
    address  = Spreadsheet.extract_address_from_filepath(params[:spreadsheet][:csv].original_filename)
    location = Location.where("lower(address) = ?", address.downcase).first
    location = Location.new(:address => address) if location.blank?
    location.latitude  = lat
    location.longitude = long
    location.neighborhood_id = @neighborhood.id
    location.city_id = @neighborhood.city_id
    location.save

    # Create a User Location corresponding to this user.
    ul = UserLocation.find_by_user_id_and_location_id(@current_user.id, location.id)
    if ul.blank?
      ul = UserLocation.create(:user_id => @current_user.id, :location_id => location.id, :source => "csv", :assigned_at => Time.zone.now)
    end

    # Create the CSV.
    @csv_report = Spreadsheet.find_by_csv_file_name(params[:spreadsheet][:csv].original_filename)
    @csv_report = Spreadsheet.new if @csv_report.blank?

    @csv_report.csv          = params[:spreadsheet][:csv]
    @csv_report.user_id      = @current_user.id
    @csv_report.location     = location
    @csv_report.save

    # Queue a job to parse the newly created CSV.
    SpreadsheetParsingWorker.perform_async(@csv_report.id)

    render :json => {:message => I18n.t("activerecord.success.report.create"), :redirect_path => csv_reports_path}, :status => 200 and return
  end

      #----------------------------------------------------------------------------
  # POST /api/v0/csv_reports/geolocation

  def geolocation

    if params[:neighborhood_id].blank?
      raise API::V0::Error.new(I18n.t("Seleccione la comunidad"), 422) and return
    end
    if params[:multiple_csv].blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422) and return
    end
    # Find the neighborhood.
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])
    CityBlock.import(params[:multiple_csv], @neighborhood)

    redirect_to geolocation_csv_reports_path, :notice => I18n.t("activerecord.success.report.create_geo")

  end

  

  #----------------------------------------------------------------------------
  # POST /api/v0/csv_reports/batch

  def batch
    # Let's iterate over each uploaded CSV, and
    # 1. Parsing the file name,
    # 2. Making sure that the location exists,
    csvs = []
    params[:multiple_csv].each do |csv|
      address  = Spreadsheet.extract_address_from_filepath(csv.original_filename)
      location = Location.where("lower(address) = ?", address.downcase).first
      if location.blank?
        raise API::V0::Error.new("¡Uy! No se pudo encontrar lugar para #{csv.original_filename}", 422) and return
      end

      csvs << {:csv => csv, :location => location}
    end

    csvs.each do |csv_hash|
      csv      = csv_hash[:csv]
      location = csv_hash[:location]

      @csv_report = Spreadsheet.find_by_csv_file_name(csv.original_filename)
      @csv_report = Spreadsheet.new if @csv_report.blank?

      @csv_report.csv             = csv
      @csv_report.user_id         = @current_user.id
      @csv_report.location_id     = location.id
      @csv_report.save(:validate => false)

      SpreadsheetParsingWorker.perform_async(@csv_report.id)
    end

    render :json => {:message => I18n.t("activerecord.success.report.create"), :redirect_path => csv_reports_path}, :status => 200 and return
  end

  # Static method called upon by the ODK sync worker
  def self.batch(params)
    # ToDo: associate csv_uuid with location form id (the main ID of the ODK form)
    # ToDo: check that all the locations for Asunción exist in database
    # ToDo: Process inspection pictures if there are (extract the URL, donwload and save)
    # ToDo: Process inspection larvae pictures if there are (extract the URL, donwload and save)
    # ToDo: If a breeding site code is the same than that found in same location with same code, consider it the same br site
    # ToDo: integrate a CSV parsing library (to prevent issues with quoting, double-quoting, different types of separators, etc.)
    # Use the generated CSV and then re-use excel parsing to upload the data
    # Let's iterate over each uploaded CSV, and
    # 1. Parsing the file name,
    # 2. Making sure that the location exists,
      csv = params[:csv]
      file_name = params[:file_name]
      username = params[:username]
      source = params[:source]
      organization_id = params[:organization_id]
      contains_photo_urls = params[:contains_photo_urls]
      username_per_inspections = params[:username_per_inspections]
      contains_photo_urls     = contains_photo_urls.nil? ? false : contains_photo_urls
      username_per_inspections  = username_per_inspections.nil? ? false : username_per_inspections
      source                  = source.nil? ? "" : source


      address  = Spreadsheet.extract_address_from_filepath(params[:file_name])

      location = Location.where("lower(address) = ?", address.downcase).first
      if location.blank?
        return;
      end

      
      @csv_report = Spreadsheet.find_by_csv_file_name(file_name)
      @csv_report = Spreadsheet.new if @csv_report.blank?

      @csv_report.csv                     = csv

      user = User.find_by_username(username)

      #si esta definido un usuario por defecto en los parametros, el mismo es usado, si no, se asigna la carga del csv a un usuario seleccionado de manera aleatoria
      @csv_report.user_id         = user != nil ? user.id  : Membership.where(organization_id: organization_id).sample.user_id
      @csv_report.location_id     = location.id
      @csv_report.csv_content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      @csv_report.contains_photo_urls = contains_photo_urls
      @csv_report.username_per_inspections = username_per_inspections
      @csv_report.source = source
      @csv_report.save(:validate => false)

      Rails.logger.debug "CSV report saved, starting parsing of the excel CSV: #{@csv_report.id}"
      SpreadsheetParsingWorker.perform_async(@csv_report.id)  # use .perform for local testing in rails console

    # render :json => {:message => I18n.t("activerecord.success.report.create"), :redirect_path => csv_reports_path}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/csv_reports/:id

  def update
    if @csv.blank?
      raise API::V0::Error.new("CSV ya eliminado o no es tu CSV", 422) and return
    end

    if @csv.update_attributes(spreadsheet_params)
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@csv.errors.full_messages[0], 422) and return
    end
  end


  #----------------------------------------------------------------------------
  # DELETE /api/v0/csv_reports/:id

  def destroy
    @csv = @current_user.csvs.find_by_id(params[:id])
    if @csv.blank?
      raise API::V0::Error.new("CSV ya eliminado o no es tu CSV", 422) and return
    end

    if @csv.destroy
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@csv.errors.full_messages[0], 422) and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/csv_reports/:id/verify

  def verify
    @csv.update_column(:verified_at, Time.zone.now)
    render :json => {:reload => true}, :status => 200 and return
  end


  #----------------------------------------------------------------------------

  private

  def spreadsheet_params
    params.require(:spreadsheet).permit(Spreadsheet.permitted_params)
  end

  def identify_csv
    if @current_user.coordinator? || @current_user.delegator?
      @csv = Spreadsheet.find_by_id(params[:id])
    else
      @csv = @current_user.csvs.find_by_id(params[:id])
    end
  end


end