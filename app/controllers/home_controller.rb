class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new

    # Select a neighborhood to showcase.
    @all_neighborhoods = Neighborhood.order(:id).limit(3)
    @neighborhood      = @all_neighborhoods.first

    # Display ordered news.
    @notices  = @neighborhood.notices.order("date DESC").limit(6)

    # Display teams.
    @teams = @neighborhood.teams
    @teams = @teams.find_all {|t| t.users.count > 0}
    @teams = @teams.shuffle[0..7]

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
    @news_feed  = (@reports.to_a + @user_posts.to_a).sort{|a,b| b.created_at <=> a.created_at }

    # Display the appropriate introduction video on homepage.
    if I18n.locale == :es
      @introductory_video_on_dengue = "http://www.youtube.com/embed/tp8Ti8-utF8?rel=0"
    else
      @introductory_video_on_dengue = "http://www.youtube.com/embed/o6IY0NjdmZc?rel=0"
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

  private

  #----------------------------------------------------------------------------

  def redirect_if_logged_in
    flash.keep(:notice)
    flash.keep(:alert)
    redirect_to user_path(@current_user) if @current_user.present?
  end

  #----------------------------------------------------------------------------

end
