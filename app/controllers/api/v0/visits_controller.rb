# -*- encoding : utf-8 -*-
class API::V0::VisitsController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt, :only => [:create, :index, :show]

  # NOTE: We're starting to blend API calls from mobile and web which is why
  # we have to start checking for cookies[:auth_token] or JWT.
  # before_action :current_user, :only => [:update]
  before_action :authenticate_user_via_cookies_or_jwt, :only => [:update]


  #----------------------------------------------------------------------------
  # GET /api/v0/visits/search

  def search
    raise API::V0::Error.new("You need to enter a date", 422) and return if params[:date].blank?
    begin
      date = Time.parse(params[:date])
    rescue
      raise API::V0::Error.new("We couldn't parse the date. Can you change the format?", 422) and return
    end

    @visits = Visit.where("DATE(visited_at) = ?", date.strftime("%Y-%m-%d")).order("visited_at DESC").limit(20)
  end

  #----------------------------------------------------------------------------
  # GET api/v0/visits

  def index
    scopes, user = request.env.values_at :scopes, :user

    @user   = User.find_by_username(user['username'])
    locids  = @user.locations.pluck(:id)
    locids += @user.csvs.pluck(:id)
    @visits = Visit.where(:location_id => locids.uniq).order("visited_at DESC").limit(25)
  end

  #----------------------------------------------------------------------------
  # GET api/v0/visits/:id

  def show
    scopes, user = request.env.values_at :scopes, :user

    @user = User.find_by_username(user['username'])
    @visit = Visit.find_by_id(params[:id])
  end

  #----------------------------------------------------------------------------
  # POST api/v0/visits

  # There are two different requests coming in:
  # 1. The location_id is known.
  # 2. The location_id is not known, but location_address is supplied.
  def create
    if params[:visit][:location_address].present?
      location = Location.where("LOWER(address) = ?", params[:visit][:location_address].strip.downcase).first
      raise API::V0::Error.new("We couldn't find that location. Please try again.", 403) if location.blank?
      location_id = location.id
    else
      location_id = params[:visit][:location_id]
    end

    # At this point, the location is known.
    @visit = Visit.new(:location_id => location_id)

    visited_at = nil
    begin
      visited_at = Time.zone.parse(params[:visit][:visited_at])
    rescue
      raise API::V0::Error.new("We couldn't parse the date. Please try again!", 403) and return
    end

    if visited_at.nil?
      raise API::V0::Error.new("We couldn't parse the date. Please try again!", 403) and return
    end

    existing_visit = Visit.find_by_location_id_and_date(location_id, visited_at)
    if existing_visit.present?
      raise API::V0::Error.new("A visit with this date and location already exists!", 403)
    end

    # At this point, a visit with this location and date doesn't exist. Let's create it.
    @visit.visited_at = visited_at
    @visit.source     = "mobile" # Right now, this API endpoint is only used by our mobile endpoint.
    if @visit.save
      render :json => {}, :status => 200 and return
    else
      raise API::V0::Error.new(@visit.errors.full_messages[0], 403)
    end
  end


  #----------------------------------------------------------------------------
  # PUT api/v0/visits/:id

  def update
    @visit = Visit.find_by_id(params[:id])

    @location = Location.where("LOWER(address) = ?", params[:visit][:location_address].strip.downcase).first
    if @location.blank?
      raise API::V0::Error.new("We couldn't find a location with that address. Please try again.", 403) and return
    end

    @visit.location_id = @location.id

    if @visit.update_attributes(params[:visit])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@visit.errors.full_messages[0], 403)
    end
  end
end
