class NeighborhoodsController < NeighborhoodsBaseController

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @neighborhood = Neighborhood.find(params[:id])

    # Identify the different types of users in the community.
    @participants = @neighborhood.members.where('role != ?', User::Types::SPONSOR).where(is_blocked: false).order(:first_name)
    @sponsors     = @neighborhood.members.where(:role => User::Types::SPONSOR).where(is_blocked: false)

    @teams = @neighborhood.teams
    @teams = @teams.find_all { |t| t.users.count > 0 }

    @reports = @neighborhood.reports
    @notices = @neighborhood.notices.order("updated_at DESC")

    @total_reports_in_neighborhood      = @reports.count
    @opened_reports_in_neighborhood     = @reports.where( :status => Report::STATUS[:reported] ).count
    @eliminated_reports_in_neighborhood = @reports.where( :status => Report::STATUS[:eliminated] ).count

    @total_points = @neighborhood.total_points

    @posts = []
    community_coordinators = @participants.where("role = ? OR role = ?", User::Types::COORDINATOR, User::Types::VERIFIER)
    community_coordinators.each do |cc|
      @posts << cc.posts
    end
    @posts.flatten!

    @news_feed = (@posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
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
