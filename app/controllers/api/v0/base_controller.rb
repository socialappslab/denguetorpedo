class API::V0::BaseController < ApplicationController
  before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------

  class API::V0::Error < StandardError
    attr :message
    attr :status_code

    def initialize(error_msg, error_status_code)
      @message     = error_msg
      @status_code = error_status_code
    end
  end

  rescue_from API::V0::Error, :with => :render_json_with_exception

  #----------------------------------------------------------------------------

  private

  def authenticate_user_via_device_token
    token = request.headers["DengueChat-API-V0-Device-Session-Token"]

    puts "\n\n\n\nTOKEN: #{token}\n\n\n"

    d = DeviceSession.find_by_token(token)
    if d.present?
      @user = d.user
      return true
    end

    raise API::V0::Error.new("Device couldn't be authenticated. Please login again.", 401) and return
  end


  def render_json_with_exception(exception)
    render :json => { :message => exception.message }, :status => exception.status_code
  end

  #----------------------------------------------------------------------------
end
