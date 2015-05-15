# -*- encoding : utf-8 -*-

class Dashboard::LocationsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/locations

  def index
    @locations = @neighborhood.locations.order("address ASC")

    # At this point, we can start limiting the number of reports we return.
    @pagination_count  = @locations.count
    @pagination_limit  = 50
    offset = (params[:page] || 0).to_i * @pagination_limit
    @locations = @locations.limit(@pagination_limit).offset(offset)

    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
  end

  #----------------------------------------------------------------------------

end
