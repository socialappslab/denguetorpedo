# -*- encoding : utf-8 -*-

class Dashboard::LocationsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/locations

  def index
    @locations = @neighborhood.locations.order("address ASC")

    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
  end

  #----------------------------------------------------------------------------

end
