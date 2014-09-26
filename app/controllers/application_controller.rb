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
  # Ensure that only coordinators are allowed access.

  def ensure_proper_permissions
    return if @current_user && @current_user.coordinator?

    flash[:alert] = I18n.t("views.application.permission_required")
    redirect_to root_path and return
  end

  #----------------------------------------------------------------------------

  def current_user
    @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
  end

  #----------------------------------------------------------------------------

  private

  def ensure_team_chosen
    return if @current_user.nil?

    if @current_user.teams.count == 0
      flash[:notice] = I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    end
  end

  def set_locale
    # The choice to set a language is given by the following rules, in order
    # of importance:
    # 1. If user is logged in, and has locale set, use that locale (if compatible),
    # 2. If no locale is set, then extract browser's default language
    #    and use it (if compatible),
    # 3. Default to I18n.default_locale if all else fails.
    available = [User::Locales::PORTUGUESE, User::Locales::SPANISH]
    if @current_user.present? && available.include?(@current_user.locale)
      I18n.locale = @current_user.locale
    else
      I18n.locale = http_accept_language.compatible_language_from(available) || I18n.default_locale
    end

    if I18n.locale.to_s == User::Locales::SPANISH
      @facebook_locale = "es_LA"
    else
      @facebook_locale = "pt_BR"
    end
  end

  #----------------------------------------------------------------------------


end
