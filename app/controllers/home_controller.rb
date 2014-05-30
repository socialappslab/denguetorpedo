class HomeController < ApplicationController
  before_filter :redirect_if_logged_in, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new

    @all_neighborhoods     = Neighborhood.order(:id).limit(3)
    @selected_neighborhood = @all_neighborhoods.first

    # Display ordered news.
    @notices  = @selected_neighborhood.notices.order("date DESC").limit(6)

    # Display 5 non-empty houses.
    @houses = @selected_neighborhood.houses.where("house_type != ?", User::Types::SPONSOR)
    @houses = @houses.find_all {|h| h.members.count > 0}
    @houses = @houses.shuffle[0..4]

    # Display active prizes.
    @prizes  = Prize.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new).order("RANDOM()").limit(3)


    # Load the news feed.
    @user_posts = Post.order(:created_at).limit(3)
    @reports    = Report.where(:neighborhood_id => @selected_neighborhood.id).order(:created_at).limit(3)
    @reports    = @reports.find_all {|r| r.is_public? }

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

end
