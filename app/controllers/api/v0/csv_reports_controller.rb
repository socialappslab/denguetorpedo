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
    if lat.blank? || long.blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.missing_location"), 422)
    end

    if params[:csv_report].blank?
      raise API::V0::Error.new(I18n.t("views.csv_reports.flashes.unknown_format"), 422)
    end

    # Create the CSV.
    @csv_report         = CsvReport.new
    @csv_report.csv     = params[:csv_report][:csv]
    @csv_report.user_id = @current_user.id
    @csv_report.save

    # Queue a job to parse the newly created CSV.
    CsvParsingWorker.perform_async(@csv_report.id, params)

    render :json => {:message => I18n.t("activerecord.success.report.create"), :redirect_path => csv_reports_path}, :status => 200 and return
  end

  #----------------------------------------------------------------------------

end
