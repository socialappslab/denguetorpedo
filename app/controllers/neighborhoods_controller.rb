class NeighborhoodsController < NeighborhoodsBaseController

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @neighborhood = Neighborhood.find(params[:id])
    @participants = @neighborhood.members.where('role != ?', "lojista").where(is_blocked: false).order(:first_name)
    @participants_view_active = ''

    @houses                             = @neighborhood.houses
    @total_reports_in_neighborhood      = @neighborhood.total_reports.count
    @opened_reports_in_neighborhood     = @neighborhood.open_reports.count
    @eliminated_reports_in_neighborhood = @neighborhood.eliminated_reports.count

    @notices = @neighborhood.notices.order("updated_at DESC")

    @houses_view_active = ''

    if params[:view] == 'participants'
      @participants_view_active = 'active'
    else # view == houses
      @houses_view_active = 'active '
    end

    @coordinators = @participants.where(:role => "coordenador")
    @verifiers = @participants.where(:role => "verificador")
    @coordinator_blogs = @participants.where(:role => "coordenador").map { |coor| coor.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at}
    @verifier_blogs = @participants.where(:role => "verificador").map { |veri| veri.posts.last }.select{ |x| !x.nil?}.sort { |x, y| y.created_at <=> x.created_at }



    @sponsors = @neighborhood.members.where(:role => "lojista")
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
