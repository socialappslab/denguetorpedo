class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token, :only => [:crate]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    device   = params[:device]

    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?


    if user.present? && user.authenticate(params[:password]) && device
    else
      raise Api::V0::Error.new("Invalid email or password. Please try again.", 401) and return
    end

  end

  #----------------------------------------------------------------------------
end
