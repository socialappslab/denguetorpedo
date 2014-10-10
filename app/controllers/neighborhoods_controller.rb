class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen, :only => [:show]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @post = Post.new

    # Load associations.
    @neighborhood = Neighborhood.find(params[:id]) if @neighborhood.nil?
    @users   = @neighborhood.members.where(:is_blocked => false).order("first_name ASC")
    @teams   = @neighborhood.teams.order("name ASC")
    @reports = @neighborhood.reports
    @notices = @neighborhood.notices

    # Limit the amount of records we show.
    @total_reports = @reports.count
    @total_points  = @users.sum(:total_points)

    if params[:feed].to_s == "1"
      @posts = @users.includes(:posts).map {|u| u.posts }.flatten
    else
      @posts   = @users.includes(:posts).map {|u| u.posts.order("updated_at DESC").limit(3)}.flatten
      @reports = @reports.order("updated_at DESC").limit(5)
      @notices = @notices.order("updated_at DESC").limit(5)
    end

    @activity_feed = (@posts.to_a + @reports.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
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

end
