class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen, :only => [:show]

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @neighborhood = Neighborhood.find(params[:id])

    # Identify the users, and reports.
    @participants = @neighborhood.members.includes(:posts).where(is_blocked: false).order("first_name ASC")
    @reports      = @neighborhood.reports
    @notices      = @neighborhood.notices.order("updated_at DESC")

    @teams = @neighborhood.teams.order("name ASC")
    @teams = @teams.find_all { |t| t.users.count > 0 }

    @total_reports_in_neighborhood      = @reports.count
    @opened_reports_in_neighborhood     = @reports.find_all {|r| r.open? }.count
    @eliminated_reports_in_neighborhood = @reports.find_all {|r| r.eliminated? }.count

    @total_points = @neighborhood.total_points

    @posts = []
    @participants.each do |cc|
      @posts << cc.posts
    end
    @posts.flatten!

    @news_feed = (@reports.to_a + @posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/invitation
  #------------------------------

  def invitation
    @title    = "Participar da Dengue Torpedo"
    @feedback = Feedback.new
  end

  #----------------------------------------------------------------------------
end
