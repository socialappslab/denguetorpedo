# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :current_user
  before_filter :set_locale

  #----------------------------------------------------------------------------

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    render :file => "public/401.html", :status => :unauthorized
  end

  #----------------------------------------------------------------------------
  # This is used for all ActiveAdmin-related resources.

  def set_active_admin_locale
    I18n.locale = :en
  end

  #----------------------------------------------------------------------------

  protected

  #----------------------------------------------------------------------------

  def require_login
    @current_user ||= User.find_by_auth_token( params[:auth_token] )
    if @current_user.nil?
      flash[:alert] = I18n.t("views.application.login_required")
      redirect_to new_user_path
    end
  end

  #----------------------------------------------------------------------------

  def require_admin
    is_admin = [User::Types::COORDINATOR, User::Types::ADMIN].include?(@current_user.role)
    unless is_admin
       redirect_to root_url
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def current_user
    @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
  end

  #----------------------------------------------------------------------------

  def ensure_team_chosen
    return if @current_user.nil?

    if @current_user.teams.count == 0
      flash[:notice] = I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    end
  end

  #----------------------------------------------------------------------------

  def set_locale
    if cookies[:locale_preference].nil?
      cookies[:locale_preference] = params[:locale] || I18n.default_locale
    else
      cookies[:locale_preference] = params[:locale] if params[:locale].present?
    end
    I18n.locale = cookies[:locale_preference]

    if I18n.locale == :pt
      @facebook_locale = "pt_BR"
    elsif I18n.locale == :es
      @facebook_locale = "es_LA"
    else
      @facebook_locale = "en_US"
    end
  end

  #----------------------------------------------------------------------------


end
