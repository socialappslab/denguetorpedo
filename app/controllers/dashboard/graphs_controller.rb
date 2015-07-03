# -*- encoding : utf-8 -*-

class Dashboard::GraphsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index, :heatmap]

  #----------------------------------------------------------------------------
  # GET /dashboard/graphs

  def index
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
  end

  #----------------------------------------------------------------------------
  # GET /dashboard/heatmap

  def heatmap
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}

    reports_with_locs = Report.joins(:location).select("latitude, longitude")
    @open_locations   = reports_with_locs.is_open
    @open_locations   = @open_locations.uniq
  end

  #----------------------------------------------------------------------------

end
