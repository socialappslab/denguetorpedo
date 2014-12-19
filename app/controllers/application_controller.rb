# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :current_user
  before_filter :set_locale
  before_filter :get_new_notifications

  before_filter :identify_for_segmentio
  before_filter :get_locale_specific_url

  # TODO: Work through this some other time. As of 2014-12-18, we should
  # focus on other efforts.
  # before_filter :set_time_zone

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

  def get_new_notifications
    return if @current_user.blank?
    notifications = @current_user.user_notifications.where(:viewed => [nil, false])
    @message_notifications = notifications.where(:notification_type => UserNotification::Types::MESSAGE)
  end

  #----------------------------------------------------------------------------

  def prepare_base64_image_for_paperclip(base64_image, filename = nil)
    # NOTE: We have to use this hack (even though Paperclip handles base64 images)
    # because we want to explicitly specify the content type and filename. Some
    # of this is taken from
    # https://github.com/thoughtbot/paperclip/blob/master/lib/paperclip/io_adapters/data_uri_adapter.rb
    # and
    # https://gist.github.com/WizardOfOgz/1012107
    regexp = /\Adata:([-\w]+\/[-\w\+\.]+)?;base64,(.*)/m
    data_uri_parts = base64_image.match(regexp) || []
    data = StringIO.new(Base64.decode64(data_uri_parts[2] || ''))
    data.class_eval do
      attr_accessor :content_type, :original_filename
    end
    data.content_type = "image/jpeg"
    data.original_filename = filename || SecureRandom.base64 + ".jpg"

    return data
  end


  #----------------------------------------------------------------------------

  private

  def set_time_zone
    Time.zone = "America/Guatemala"
    if current_user
      Time.zone = current_user.neighborhood.time_zone
    end
  end

  def identify_for_segmentio
    return unless Rails.env.production?

    if @current_user
      Analytics.identify( user_id: @current_user.id, traits: { username: @current_user.username })
    end
  end

  def ensure_team_chosen
    return if @current_user.nil?

    if @current_user.teams.count == 0
      flash[:notice] = I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    end
  end

  def set_locale
    # raise "cookies[:locale_preference]: #{cookies[:locale_preference]}"
    # The choice to set a language is given by the following rules, in order
    # of importance:
    # 1. If user is logged in, and has locale set, use that locale (if compatible),
    # 2. If no locale is set, then use the cookies[:locale_preference] attribute,
    # according to the following:
    # 2a. Set cookies to whatever params[:locale], if present,
    # 2b. If not present, and cookies are not set, then set it to
    #     browser's default language.
    # 2c. Fallback to I18n.default_locale if all else fails.
    available = [User::Locales::PORTUGUESE, User::Locales::SPANISH]
    if @current_user.present? && available.include?(@current_user.locale)
      I18n.locale = @current_user.locale
    else
      cookies[:locale_preference] = params[:locale] if params[:locale].present?
      if cookies[:locale_preference].blank?
        cookies[:locale_preference] = http_accept_language.compatible_language_from(available) || I18n.default_locale
      end

      I18n.locale = cookies[:locale_preference]
    end

    if I18n.locale.to_s == User::Locales::SPANISH
      @facebook_locale = "es_LA"
    else
      @facebook_locale = "pt_BR"
    end
  end

  def get_locale_specific_url
    host = (I18n.locale.to_s == User::Locales::PORTUGUESE ? "www.denguetorpedo.com" : "www.denguechat.org")
    @locale_specific_url = "https://#{host}#{request.path}"
  end

  #----------------------------------------------------------------------------

end
