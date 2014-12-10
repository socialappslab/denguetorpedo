class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen, :only => [:show]


  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @post = Post.new

    # Load associations.
    @neighborhood = Neighborhood.find(params[:id])
    @users   = @neighborhood.users.where(:is_blocked => false).order("first_name ASC")
    @teams   = @neighborhood.teams.order("name ASC")
    @reports = @neighborhood.reports
    @notices = @neighborhood.notices.order("updated_at DESC")

    # Calculate total visits to (different) locations.
    @visits       = @reports.map {|r| r.location}.compact.uniq
    @total_locations     = @visits.count
    @positive_locations  = @visits.find_all {|l| l.status == Location::Status::POSITIVE}.count
    @potential_locations = @visits.find_all {|l| l.status == Location::Status::POTENTIAL}.count
    @negative_locations  = @visits.find_all {|l| l.status == Location::Status::NEGATIVE}.count
    @clean_locations     = @visits.find_all {|l| l.status == Location::Status::CLEAN}.count

    @statistics = LocationStatus.calculate_affected_percentages_by_day(@visits)


    # Calculate total metrics before we start filtering.
    @total_reports = @reports.count
    @total_points  = @neighborhood.total_points

    # Limit the activity feed to *current* neighborhood members.
    user_ids = @users.pluck(:id)
    @reports = @reports.order("updated_at DESC").where("reporter_id IN (?) OR verifier_id IN (?) OR resolved_verifier_id IN (?) OR eliminator_id IN (?)", user_ids, user_ids, user_ids, user_ids)
    @posts   = @neighborhood.posts.where(:user_id => user_ids).order("updated_at DESC")

    # Limit the amount of records we show.
    unless params[:feed].to_s == "1"
      @posts   = @posts.limit(3)
      @reports = @reports.limit(5)
      @notices = @notices.limit(5)
    end

    @activity_feed = (@posts.to_a + @reports.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited a neighborhood page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited a neighborhood page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    end
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
