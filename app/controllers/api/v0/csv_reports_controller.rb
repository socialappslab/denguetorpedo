# -*- encoding : utf-8 -*-

class API::V0::CsvReportsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user
  before_filter :set_locale

  #----------------------------------------------------------------------------
  # POST /api/v0/csv_reports

  # We assume the user will upload a specific CSV (or .xls, .xlsx) template.
  # Once uploaded, we parse the CSV and assign a UUID to each row which
  # will be saved with a new report (if it's ever created).
  # If a report exists with the UUID, then we update that report instead of
  # creating a new one.
  def create
    @neighborhood = Neighborhood.find(params[:neighborhood_id])
    @csv_report   = CsvReport.new

    # Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.missing_location"), 422)
    end

    if params[:csv_report].blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422)
    end

    # 2. Identify the file content type.
    file        = params[:csv_report][:csv]
    spreadsheet = CsvReport.load_spreadsheet( file )
    unless spreadsheet
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422)
    end


    # TODO
    @csv_report.csv         = file
    @csv_report.user_id     = @current_user.id
    @csv_report.save


    render :json => {:message => notice, :redirect_path => redirect_path}, :status => 200 and return
  end

  #----------------------------------------------------------------------------

end
