# -*- encoding : utf-8 -*-
class API::V0::LocationsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt, :only => [:search, :mobile, :show]
  before_action :current_user_via_jwt,      :only => [:search, :mobile, :show]

  #----------------------------------------------------------------------------
  # GET /api/v0/locations/search

  def search
    raise API::V0::Error.new("You need to enter an address", 422) and return if params[:address].blank?

    @locations = Location.where("lower(address) LIKE ?", "%#{params[:address].strip.downcase}%").order("address ASC").limit(20)
    if @locations.blank?
      raise API::V0::Error.new("No pudo encontrar lugar con la dirección #{params[:address]}", 422) and return
    end
  end


  #----------------------------------------------------------------------------
  # GET /api/v0/locations/mobile
  # TODO: See if you can replace #index with this method, but beware that #index
  # is used by DashboardController.

  def mobile
    @locations = @current_user.neighborhood.locations.joins(:visits).order("visits.visited_at DESC").limit(20)
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/locations/:id

  def show
    @location = @current_user.neighborhood.locations.find_by_id(params[:id])
  end

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

    @locations = Location.where(:id => location_ids).order("address ASC").includes(:visits, :reports)
    render "api/v0/locations/index" and return
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/locations/house-index
  def house_index
    city   = @current_user.city
    nids   = city.neighborhoods.pluck(:id)
    locids_from_visits = Visit.where("csv_id IS NOT NULL").pluck(:location_id)

    @locations = Location.where(:neighborhood_id => nids).where(:id => locids_from_visits)
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/locations/

  def create
    @location = Location.where("LOWER(address) = ?", params[:location][:address].strip.downcase)
    if @location.present?
      raise API::V0::Error.new("Location with that address already exists. Try searching for it!", 422) and return
    end

    @location = Location.new(params[:location])
    if @location.save
      render :json => @location.to_json, :status => 200 and return
    else
      raise API::V0::Error.new(@location.errors.full_messages[0], 422) and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/locations/:id

  def update
    @location = Location.find_by_id(params[:id])
    if @location.update_attributes(location_params)
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@location.errors.full_messages[0], 422) and return
    end
  end


  #----------------------------------------------------------------------------

  private

  def location_params
    params.require(:location).permit(Location.permitted_params)
  end
end
