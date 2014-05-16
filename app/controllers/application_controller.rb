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

  def is_admin?
    ["coordenador", "admin"].include? @current_user.role
  end

  #----------------------------------------------------------------------------

  def require_login
    @current_user ||= User.find_by_auth_token(params[:auth_token])
    flash[:alert] = "Faça o seu login para visualizar essa página." if @current_user.nil?
    redirect_to root_url if @current_user.nil?
    # head :u and return if @current_user.nil?
  end

  #----------------------------------------------------------------------------

  def require_admin
    unless is_admin?
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
