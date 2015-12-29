# -*- encoding : utf-8 -*-

class API::V0::CsvReportsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user
  before_filter :set_locale

  #----------------------------------------------------------------------------
  # POST /api/v0/csv_reports

  # We assume the user will upload a particular CSV only once. This means that
  # a 'rolling update' to any CSV will be treated as different CSVs.
  def create
    # Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    address = params[:location][:address]
    if lat.blank? || long.blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.missing_location"), 422) and return
    end

    if address.blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.missing_address"), 422) and return
    end

    if params[:spreadsheet].blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422) and return
    end

    # Find the neighborhood.
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])

    # Create or find the location.
    location = Location.find_by_address(address)
    location = Location.new(:address => address) if location.blank?
    location.latitude  = lat
    location.longitude = long
    location.neighborhood_id = @neighborhood.id
    location.save

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
  # POST /api/v0/csv_reports/batch

  def batch
    # Let's iterate over each uploaded CSV, and
    # 1. Parsing the file name,
    # 2. Making sure that the location exists,
    csvs = []
    params[:multiple_csv].each do |csv|
      filename = csv.original_filename.split("/").last
      filename = filename.split(".").first.strip
      location = Location.where("lower(address) = ?", filename.downcase).first
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


  #----------------------------------------------------------------------------
  # PUT /api/v0/csv_reports/:id

  def update
    @csv = @current_user.csvs.find_by_id(params[:id])
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
    @csv = @current_user.csvs.find(params[:id])
    @csv.update_column(:verified_at, Time.zone.now)
    render :json => {:reload => true}, :status => 200 and return
  end


  #----------------------------------------------------------------------------

  private

  def spreadsheet_params
    params.require(:spreadsheet).permit(Spreadsheet.permitted_params)
  end

end
