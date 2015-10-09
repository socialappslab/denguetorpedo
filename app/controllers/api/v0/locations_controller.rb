# -*- encoding : utf-8 -*-
class API::V0::LocationsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/locations
  # Parameters:
  # * neighborhood_id
  # * CSV data
  def index

    location_ids = []
    params[:addresses].split(",").each do |address|
      loc = Location.where("lower(address) = ?", address.strip.downcase).first
      if loc.blank?
        raise API::V0::Error.new("No pudo encontrar lugar con la dirección #{address}", 422) and return
      end

      location_ids << loc.id
    end

    @locations = Location.where(:id => location_ids).includes(:visits, :reports)
    render "api/v0/locations/index" and return
  end
end
