# -*- encoding : utf-8 -*-
class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token, :only => [:create, :current]
  before_filter :current_user, :only => [:current]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?

    if user.present? && user.authenticate(params[:password])
      render :json => { :token => user.jwt_token }, :status => 200
    else
      raise API::V0::Error.new("Invalid email or password. Please try again.", 401) and return
    end

  end

  #----------------------------------------------------------------------------
  # GET /api/v0/users/current

  def current
    render :json => {:user => @current_user }, :status => 200
  end

  #----------------------------------------------------------------------------
end
