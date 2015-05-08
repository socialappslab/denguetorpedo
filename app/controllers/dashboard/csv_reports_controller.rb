# -*- encoding : utf-8 -*-

class Dashboard::CsvReportsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/csv_reports

  def index
    @navigation["child"] = {"name" => "Upload CSV", "path" => new_dashboard_csv_path}

    @csvs = @current_user.csv_reports.includes(:visits)
  end

  #----------------------------------------------------------------------------
  # GET /dashboard/csv_reports/new

  def new
    @navigation["child"] = {"name" => "Cancel", "path" => dashboard_csv_index_path}

    @csv_report = CsvReport.new
    @open_locations = []
    @eliminated_locations = []
    @neighborhood = @current_user.neighborhood
  end

end
