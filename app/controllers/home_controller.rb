# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]

#----------------------------------------------------------------------------
  # GET /

  def denguechatcom
    render text: "6iEbJmeMKc1BB34je4Wu1MtrDZemh3cB3YqpHjlp7cc.x63o5CYgK-zeqySMz_nJt3vKipih1P5E2ooiiS6t1ec"
  end

  def denguechatorg
    render text: "cY1aep05zjfm0KS8w7OR1RJ60PXjbUBtUIOdPJ-5YXk.x63o5CYgK-zeqySMz_nJt3vKipih1P5E2ooiiS6t1ec"
  end

  def index
    @user = User.new

    # We're manually ordering this to display the diversity of
    # our cities.
    @citiesThatUsed = City.find_by_sql("SELECT cities.* from cities join
    (values ('Rio de Janeiro', 1), ('Cuernavaca', 2), ('Tepalcingo', 3)) as cityorder (name, ordering)
    ON cities.name = cityorder.name ORDER BY cityorder.ordering")
    
    @citiesUsing = City.find_by_sql("SELECT cities.* from cities join
      (values ('Managua', 1), ('Asunción', 2), ('Armenia', 3)) as cityorder (name, ordering)
      ON cities.name = cityorder.name ORDER BY cityorder.ordering")
    @neighborhood_select = []
    @citiesThatUsed.each do |c|
      @neighborhood_select += c.neighborhoods.order("name ASC").map {|n| ["#{n.name}, #{c.name}", n.id]}
    end

    # Display the appropriate introduction video on homepage.
    if I18n.locale == :es
      @introductory_video_on_dengue = "//www.youtube.com/embed/hwod5NOxiNM?rel=0"
      @introductory_video_on_dengue_py = "//www.youtube.com/embed/WLVJadIHqDA"
    else
      @introductory_video_on_dengue = "//www.youtube.com/embed/o6IY0NjdmZc?rel=0"
      
    end

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited homepage") if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited homepage") if Rails.env.production?
    end

    @landing_page_photo_ni = (1..3).to_a.map {|index| "landing/landing_#{index}.png"}.sample
    @landing_page_photo_py = (7..11).to_a.map {|index| "landing/landing_#{index}.png"}.sample
    @landing_page_photo_co = (4..6).to_a.map {|index| "landing/landing_#{index}.png"}.sample
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