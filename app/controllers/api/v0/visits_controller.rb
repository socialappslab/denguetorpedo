# -*- encoding : utf-8 -*-
class API::V0::VisitsController < API::V0::BaseController
  # skip_before_action :authenticate_user_via_device_token
  # before_action :authenticate_user_via_jwt, :only => [:index]
  before_action :current_user, :only => [:update]

  #----------------------------------------------------------------------------
  # GET api/v0/visits

  def index
    scopes, user = request.env.values_at :scopes, :user

    @user = User.find_by_username(user['username'])
    @visits = Visit.limit(25)
    render :json => {:visits => @visits} and return
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
