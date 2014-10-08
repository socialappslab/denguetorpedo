class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen, :only => [:show]
  before_filter :load_associations,  :only => [:show, :feed]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @post = Post.new

    # Limit the amount of records we show.
    @total_reports = @reports.count
    @total_points  = @users.sum(:total_points)
    @reports       = @reports.limit(5)
    @notices       = @notices.limit(5)
    @posts         = @users.includes(:posts).map {|u| u.posts.limit(3)}.flatten

    # Create the news feed.
    @activity_feed = (@reports.to_a + @posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/feed

  def feed
    @post          = Post.new
    @posts         = @users.includes(:posts).map {|u| u.posts }.flatten
    @activity_feed = (@reports.to_a + @posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/invitation
  #------------------------------

  def invitation
    @title    = "Participar da Dengue Torpedo"
    @feedback = Feedback.new
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def load_associations
    @neighborhood = Neighborhood.find(params[:id]) if @neighborhood.nil?

    @users   = @neighborhood.members.where(:is_blocked => false).order("first_name ASC")
    @teams   = @neighborhood.teams.order("name ASC")
    @reports = @neighborhood.reports
    @notices = @neighborhood.notices
  end

  #----------------------------------------------------------------------------

end
