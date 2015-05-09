# -*- encoding : utf-8 -*-

class Dashboard::CsvReportsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/csv_reports

  def index
    @navigation["child"] = {"name" => "Upload CSV", "path" => new_dashboard_csv_path}

    # Identify the neighborhood that the user is interested in.
    neighborhood_id = cookies[:neighborhood_id] || @current_user.neighborhood_id
    @neighborhood = Neighborhood.find_by_id(neighborhood_id)

    @csvs = CsvReport.joins(:location).where("locations.neighborhood_id = ?", neighborhood_id)
    @csvs = @csvs.includes(:visits)

    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
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
