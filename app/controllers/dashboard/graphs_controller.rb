# -*- encoding : utf-8 -*-

class Dashboard::GraphsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index, :heatmap]

  #----------------------------------------------------------------------------
  # GET /dashboard/graphs

  def index
    authorize :dashboard, :index?
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}

    # @breadcrumbs << {:name => I18n.t("views.dashboard.navigation.graphs"), :path => request.path}
  end

  #----------------------------------------------------------------------------
  # GET /dashboard/heatmap

  def heatmap
    authorize :dashboard, :index?
    # @breadcrumbs << {:name => I18n.t("views.dashboard.navigation.heatmap"), :path => request.path}
  end

  #----------------------------------------------------------------------------

end
