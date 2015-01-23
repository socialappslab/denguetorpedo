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
    @notices = @neighborhood.notices.order("updated_at DESC").where("date > ?", Time.now.beginning_of_day)

    # Calculate total visits to (different) locations.
    @visits              = @reports.includes(:location).map {|r| r.location}.compact.uniq
    @total_locations     = @visits.count

    # start_time = Time.now - 3.months
    # end_time   = Time.now
    @statistics = Visit.calculate_time_series_for_locations(@visits)
    @chart_statistics = @statistics.map {|hash|
      [
        hash[:date],
        hash[:positive][:percent],
        hash[:potential][:percent],
        hash[:negative][:percent],
        hash[:clean][:percent]
      ]
    }

    @last_statistics = []
    legend = [I18n.t("views.statistics.table.positive_sites"), I18n.t("views.statistics.table.potential_sites"),
    I18n.t("views.statistics.table.negative_sites"), I18n.t("views.statistics.table.clean_sites")]
    if @statistics.present?
      [:positive, :potential, :negative, :clean].each_with_index do |key, index|
        @last_statistics << [legend[index], @statistics.last[key][:count]]
      end
    end


    # Calculate total metrics before we start filtering.
    @total_reports = @reports.count
    @total_points  = @neighborhood.total_points

    # Limit the activity feed to *current* neighborhood members.
    user_ids = @users.pluck(:id)
    @reports = @reports.where(:protected => [nil, false]).order("updated_at DESC").where("reporter_id IN (?) OR verifier_id IN (?) OR resolved_verifier_id IN (?) OR eliminator_id IN (?)", user_ids, user_ids, user_ids, user_ids)
    @posts   = @neighborhood.posts.where(:user_id => user_ids).order("updated_at DESC")

    # Limit the amount of records we show.
    unless params[:feed].to_s == "1"
      @posts   = @posts.limit(15)
      @reports = @reports.limit(5)
    end

    @activity_feed = (@posts.to_a + @reports.to_a).sort{|a,b| b.created_at <=> a.created_at }

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
