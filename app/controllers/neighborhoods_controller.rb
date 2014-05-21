class NeighborhoodsController < NeighborhoodsBaseController

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @neighborhood = Neighborhood.find(params[:id])

    @participants = @neighborhood.members.where('role != ?', User::Types::SPONSOR).where(is_blocked: false).order(:first_name)
    @coordinators = @participants.where(:role => User::Types::COORDINATOR)
    @verifiers    = @participants.where(:role => User::Types::VERIFIER)

    # Fetch all houses that have at least one member.
    @houses = @neighborhood.houses.where("house_type != ?", User::Types::SPONSOR)
    @houses = @houses.find_all {|h| h.members.count > 0}


    @reports = @neighborhood.reports
    @notices = @neighborhood.notices.order("updated_at DESC")

    @total_reports_in_neighborhood      = @reports.count
    @opened_reports_in_neighborhood     = @reports.where( :status => Report::STATUS[:reported] ).count
    @eliminated_reports_in_neighborhood = @reports.where( :status => Report::STATUS[:eliminated] ).count

    @coordinator_blogs = @coordinators.map { |coor| coor.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at}
    @verifier_blogs    = @verifiers.map    { |veri| veri.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at }

    @houses_view_active = ''
    @participants_view_active = ''
    if params[:view] == 'participants'
      @participants_view_active = 'active'
    else # view == houses
      @houses_view_active = 'active '
    end


    @sponsors = @neighborhood.members.where(:role => User::Types::SPONSOR).where(is_blocked: false)
    @random_sponsors = []
    9.times do
      @random_sponsors.push('home_images/sponsor'+(rand(5)+1).to_s+'.png')
    end
  end

  #----------------------------------------------------------------------------
  # GET /neighborhoods/invitation
  #------------------------------

  def invitation
    @title = "Participar da Dengue Torpedo"
    @feedback = Feedback.new
  end

  #----------------------------------------------------------------------------
end
