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
  # See this for motivation: http://www.elabs.se/blog/36-working-with-time-zones-in-ruby-on-rails
  around_filter :set_time_zone

  #-------------------------------------------------------------------------------------------------

  def set_time_zone(&block)
    if current_user
      Time.use_zone(current_user.neighborhood.city.time_zone, &block)
    else
      Time.use_zone("America/Guatemala", &block)
    end
  end

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

  # This is a *heavy* method that returns time series for visits over different
  # timeframes (inferred through cookies).
  def calculate_time_series_for_visits
    start_time  = nil
    visit_types = []
    if cookies[:chart].present?
      chart_settings = JSON.parse(cookies[:chart])
      start_time = 1.month.ago  if chart_settings["timeframe"] == "1"
      start_time = 3.months.ago if chart_settings["timeframe"] == "3"
      start_time = 6.months.ago if chart_settings["timeframe"] == "6"

      # if chart_settings["positive_inspection"].present? || chart_settings["potential_inspection"].present?
      #   visit_types << Visit::Types::INSPECTION
      # end
      #
      # if chart_settings["positive_followup"].present? || chart_settings["potential_followup"].present?
      #   visit_types << Visit::Types::FOLLOWUP
      # end
      #
      # if chart_settings["percentages"].present? && chart_settings["percentages"] == "daily"
      #   @statistics = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time, visit_types)
      # end
    end

    # Calculate the statistics based on the start_time and visit_types only
    # if it hasn't been calculated yet.
    # if @statistics.blank?
    #   @statistics = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time, visit_types)
    # end

    # NOTE: We're overriding whatever options the user has chosen to
    # keep things agile for the time being.

    start = Time.now
    @statistics = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(@visit_ids, start_time, [])
    puts "\n\n\nTime diff: #{Time.now - start}\n\n\n\n\n\n"

    # Format the data in a way that Google Charts can use.
    @chart_statistics = [[I18n.t('views.statistics.chart.time'), I18n.t('views.statistics.chart.percent_of_positive_sites'), I18n.t('views.statistics.chart.percent_of_potential_sites'), I18n.t('views.statistics.chart.percent_of_negative_sites')]]
    @statistics.each do |hash|
      @chart_statistics << [
        hash[:date],
        hash[:positive][:percent],
        hash[:potential][:percent],
        hash[:negative][:percent]
      ]
    end
  end

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

  def identify_for_segmentio
    return unless Rails.env.production?

    if @current_user
      Analytics.identify( user_id: @current_user.id, traits: { username: @current_user.username })
    end
  end

  def ensure_team_chosen
    return if @current_user.nil?

    # Perform an efficient SQL query to check if the user belongs
    # to some team. Redirect if no membership is found.
    tm = TeamMembership.where(:user_id => @current_user.id).limit(1)
    if tm.blank?
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
