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

    if params[:csv_report].blank?
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
    @csv_report = CsvReport.find_by_csv_file_name(params[:csv_report][:csv].original_filename)
    @csv_report = CsvReport.new if @csv_report.blank?

    @csv_report.csv          = params[:csv_report][:csv]
    @csv_report.user_id      = @current_user.id
    @csv_report.neighborhood = @neighborhood
    @csv_report.location     = location
    @csv_report.save

    # Queue a job to parse the newly created CSV.
    CsvParsingWorker.perform_async(@csv_report.id)

    render :json => {:message => I18n.t("activerecord.success.report.create"), :redirect_path => csv_reports_path}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/csv_reports/:id

  def update
    @csv      = @current_user.csv_reports.find_by_id(params[:id])
    @location = @csv.location

    if params[:location].present?
      @location.address         = params[:location][:address]
      @location.neighborhood_id = params[:location][:neighborhood_id]
    end

    @csv.update_column(:neighborhood_id, @location.neighborhood_id)

    if @location.save
      render :json => {:redirect_path => verify_csv_report_path(@csv)}, :status => 200 and return
    else
      raise API::V0::Error.new(@location.errors.full_messages[0], 422) and return
    end
  end


  #----------------------------------------------------------------------------
  # DELETE /api/v0/csv_reports/:id

  def destroy
    @csv = @current_user.csv_reports.find(params[:id])
    if @csv.destroy
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@csv.errors.full_messages[0], 422) and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/csv_reports/:id/verify

  def verify
    @csv = @current_user.csv_reports.find(params[:id])
    @csv.update_column(:verified_at, Time.zone.now)
    render :json => {:redirect_path => csv_report_path(@csv)}, :status => 200 and return
  end


  #----------------------------------------------------------------------------

end
