# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :current_user
  before_filter :set_locale

  #----------------------------------------------------------------------------

  rescue_from CanCan::AccessDenied do |exception|
    render :file => "public/401.html", :status => :unauthorized
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
    is_admin = [User::TYPES::COORDINATOR, User::TYPES::ADMIN].include?(@current_user.role)
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
