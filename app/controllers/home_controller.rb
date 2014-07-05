class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]
  before_filter :identify_country,      :only => [:index]

  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new

    @all_neighborhoods     = Neighborhood.where(:country_string_id => @country.alpha2).order(:id).limit(3)
    @selected_neighborhood = @all_neighborhoods.first
    @neighborhood          = @selected_neighborhood

    # Display ordered news.
    @notices  = @selected_neighborhood.notices.order("date DESC").limit(6)

    # Display teams.
    @teams = @selected_neighborhood.teams
    @teams = @teams.find_all {|t| t.users.count > 0}
    @teams = @teams.shuffle[0..7]

    # Display active prizes.
    @prizes = Prize.where(:neighborhood_id => [nil, @neighborhood.id])
    @prizes = @prizes.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new).order("RANDOM()").limit(10)


    # Load the news feed.
    @user_posts = Post.order("created_at DESC").limit(3)
    @reports    = Report.where(:neighborhood_id => @selected_neighborhood.id).order("created_at DESC").limit(10)
    @reports    = @reports.find_all {|r| r.is_public? }[0..3]

    @news_feed = (@reports.to_a + @user_posts.to_a).sort{|a,b| b.created_at <=> a.created_at }
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

  private

  #----------------------------------------------------------------------------

  def redirect_if_logged_in
    redirect_to user_path(@current_user) if @current_user.present?
  end

  #----------------------------------------------------------------------------

  # NOTE: The default country is Brazil.
  def identify_country
    if I18n.locale == :es
      @country = Country.find_country_by_name("Mexico")
    else
      @country = Country.find_country_by_name("Brazil")
    end
  end

  #----------------------------------------------------------------------------

end
