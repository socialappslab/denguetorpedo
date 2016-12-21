# -*- encoding : utf-8 -*-
class API::V0::BaseController < ApplicationController
  before_action :authenticate_user_via_device_token
  before_action :set_locale

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

  protected

  def current_user_via_jwt
    scopes, user = request.env.values_at :scopes, :user
    @current_user = User.find_by_username(user["username"])
  end

  def authenticate_user_via_jwt
    begin
      bearer = request.env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }

      request.env[:scopes] = payload['scopes']
      request.env[:user]   = payload['user']
    rescue JWT::DecodeError
      raise API::V0::Error.new('A token must be passed.', 401) and return
    rescue JWT::ExpiredSignature
      raise API::V0::Error.new('The token has expired.', 403) and return
    rescue JWT::InvalidIssuerError
      raise API::V0::Error.new('The token does not have a valid issuer.', 403) and return
    rescue JWT::InvalidIatError
      raise API::V0::Error.new('The token does not have a valid "issued at" time.', 403) and return
    end
  end

  private

  def authenticate_user_via_device_token
    token = request.env["DengueChat-API-V0-Device-Session-Token"]
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
