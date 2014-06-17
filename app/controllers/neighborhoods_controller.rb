class NeighborhoodsController < NeighborhoodsBaseController

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @neighborhood = Neighborhood.find(params[:id])

    # Identify the different types of users in the community.
    @participants = @neighborhood.members.where('role != ?', User::Types::SPONSOR).where(is_blocked: false).order(:first_name)
    # @coordinators = @participants.where(:role => User::Types::COORDINATOR)
    # @verifiers    = @participants.where(:role => User::Types::VERIFIER)
    @sponsors     = @neighborhood.members.where(:role => User::Types::SPONSOR).where(is_blocked: false)

    # Fetch all houses that have at least one member.
    @houses = @neighborhood.houses.where("house_type != ?", User::Types::SPONSOR)
    @houses = @houses.find_all {|h| h.members.count > 0}

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
    # @coordinator_blogs = @coordinators.map { |coor| coor.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at}
    # @verifier_blogs    = @verifiers.map    { |veri| veri.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at }
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
