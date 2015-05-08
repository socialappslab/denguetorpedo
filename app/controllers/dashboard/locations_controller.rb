# -*- encoding : utf-8 -*-

class Dashboard::LocationsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/locations

  def index
    @neighborhood = @current_user.neighborhood
    @locations = @neighborhood.locations
  end

  #----------------------------------------------------------------------------

end
