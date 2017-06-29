# -*- encoding : utf-8 -*-

class Dashboard::LocationsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/locations

  def index
    authorize Location
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
    # @breadcrumbs << {:name => I18n.t("views.dashboard.navigation.locations"), :path => request.path}
  end

  #----------------------------------------------------------------------------

end
