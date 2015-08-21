# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new

    # We're manually ordering this to display the diversity of
    # our cities.
    @cities = City.find_by_sql("SELECT cities.* from cities join
    (values ('Rio de Janeiro', 1), ('Managua', 2), ('Cuernavaca', 3), ('Tepalcingo', 4)) as cityorder (name, ordering)
    ON cities.name = cityorder.name ORDER BY cityorder.ordering")

    @neighborhood_select = []
    @cities.each do |c|
      @neighborhood_select += c.neighborhoods.order("name ASC").map {|n| ["#{n.name}, #{c.name}", n.id]}
    end

    # Display the appropriate introduction video on homepage.
    if I18n.locale == :es
      @introductory_video_on_dengue = "https://www.youtube.com/embed/hwod5NOxiNM?rel=0"
    else
      @introductory_video_on_dengue = "https://www.youtube.com/embed/o6IY0NjdmZc?rel=0"
    end

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited homepage") if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited homepage") if Rails.env.production?
    end
  end

  #----------------------------------------------------------------------------
  # GET /howto

  def howto
    @sections = DocumentationSection.order("order_id ASC")
  end

  #----------------------------------------------------------------------------
  # POST /neighborhood-search

  def neighborhood_search
    neighborhood = Neighborhood.find_by_name(params[:neighborhood][:name])
    redirect_to neighborhood_path(neighborhood)
  end

  #----------------------------------------------------------------------------
  # GET /free-sms

  def free_sms
  end

  #----------------------------------------------------------------------------
  # POST /time-series-settings
  #------------------------------

  def time_series_settings
    settings = {}

    if params["chart"]
      if params["chart"]["timeframe"].present? && ["1", "3", "6", "-1"].include?(params["chart"]["timeframe"])
        settings["timeframe"] = params["chart"]["timeframe"]
      end

      if params["chart"]["percentages"].present? && ["daily", "cumulative"].include?(params["chart"]["percentages"])
        settings["percentages"] = params["chart"]["percentages"]
      end

      ["positive", "potential", "negative"].each do |key|
        settings[key] = params["chart"][key]
      end
    end

    cookies[:chart] = settings.to_json
    redirect_to :back and return
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def redirect_if_logged_in
    flash.keep(:notice)
    flash.keep(:alert)
    redirect_to city_path(@current_user.city) if @current_user.present?
  end

  #----------------------------------------------------------------------------

end
