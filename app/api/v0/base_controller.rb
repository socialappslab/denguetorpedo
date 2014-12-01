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

  rescue_from API::V1::Error, :with => :render_json_with_exception

  #----------------------------------------------------------------------------

  private

  def authenticate_user_via_device_token
    return true
  end

  def render_json_with_exception(exception)
    render :json => { :message => exception.message }, :status => exception.status_code
  end

  #----------------------------------------------------------------------------
end
