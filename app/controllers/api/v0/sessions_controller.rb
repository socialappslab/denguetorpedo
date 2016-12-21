# -*- encoding : utf-8 -*-
class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token, :only => [:create, :current]
  before_filter :current_user, :only => [:current]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    device = params[:device]

    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?

    if user.present? && user.authenticate(params[:password]) && device
      ds         = DeviceSession.new
      ds.user_id = user.id
      ds.token   = SecureRandom.uuid
      ds.device_name  = device[:device]
      ds.device_model = device[:model]
      ds.save!

      render :json => { :device_session => { :token => ds.token } }, :status => 200
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

  private

  #----------------------------------------------------------------------------

  def token(user)
    return JWT.encode(payload(user.username, user.email), ENV['JWT_SECRET'], 'HS256')
  end

  def payload(username, email)
    {
      exp: Time.now.to_i + 2 * 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: ['add_visits', 'change_visits', 'remove_visits', 'add_houses', 'change_houses', 'remove_houses', 'add_inspections', 'change_inspections', 'remove_inspections', 'add_breeding_sites', 'change_breeding_sites', 'remove_breeding_sites'],
      user: {
        username: username,
        email:    email
      }
    }
  end

  #----------------------------------------------------------------------------
end
