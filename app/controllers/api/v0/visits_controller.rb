# -*- encoding : utf-8 -*-
class API::V0::VisitsController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt, :only => [:index, :show]
  before_action :current_user, :only => [:update]

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
    @visit = Visit.find(params[:id])
  end

  #----------------------------------------------------------------------------
  # GET api/v0/visits/:id

  def update
    @visit = Visit.find_by_id(params[:id])
    if @visit.update_attributes(params[:visit])
      render :json => {:reload => true}, :status => 200 and return
    else
      raise API::V0::Error.new(@visit.errors.full_messages[0], 403)
    end
  end
end
