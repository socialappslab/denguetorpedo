# -*- encoding : utf-8 -*-
class API::V0::LocationsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/locations
  # Parameters:
  # * neighborhood_id
  # * CSV data
  def index
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])
    @locations    = @neighborhood.locations.includes(:visits)

    if params[:csv_only].present?
      @locations = @neighborhood.locations.where("locations.id IN (SELECT location_id FROM csv_reports)").includes(:visits)
    else
      @locations = @neighborhood.locations.includes(:visits)
    end


    render "api/v0/locations/index" and return
  end
end
