class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new

    # We're manually ordering this to display the diversity of
    # our cities.
    @cities = [ City.find_by_name("Rio de Janeiro"), City.find_by_name("Managua"), City.find_by_name("Cuernavaca"), City.find_by_name("Tepalcingo") ]

    # Display ordered news.
    @notices  = @neighborhood.notices.order("date DESC").limit(6)

    # Display teams.
    @teams = @neighborhood.teams.includes(:users)
    @teams = @teams.find_all {|t| t.users.count > 0}
    @teams = @teams.shuffle[0..6]

    # Display active prizes.
    # TODO: Allow for display of expired prizes until we have an inventory of
    # new prizes.
    # @prizes = Prize.where(:neighborhood_id => [nil, @neighborhood.id])
    # @prizes = @prizes.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new).order("RANDOM()").limit(10)
    @prizes = Prize.order("RANDOM()").limit(10)

    # Load the news feed.
    @user_posts = Post.order("created_at DESC").limit(3)
    @reports    = Report.where(:neighborhood_id => @neighborhood.id).order("created_at DESC").limit(10)
    @reports    = @reports.find_all {|r| r.is_public? }[0..3]
    @activity_feed  = (@reports.to_a + @user_posts.to_a).sort{|a,b| b.created_at <=> a.created_at }

    # Display the appropriate introduction video on homepage.
    if I18n.locale == :es
      @introductory_video_on_dengue = "http://www.youtube.com/embed/tp8Ti8-utF8?rel=0"
    else
      @introductory_video_on_dengue = "http://www.youtube.com/embed/o6IY0NjdmZc?rel=0"
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

      # ["positive_inspection", "potential_inspection", "positive_followup", "potential_followup"].each do |key|
      #   settings[key] = params["chart"][key]
      # end


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
    redirect_to user_path(@current_user) if @current_user.present?
  end

  #----------------------------------------------------------------------------

end
