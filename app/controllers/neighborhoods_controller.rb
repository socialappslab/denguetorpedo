# -*- encoding : utf-8 -*-
class NeighborhoodsController < NeighborhoodsBaseController
  before_filter :ensure_team_chosen,               :only => [:show]
  before_filter :calculate_ivars,                  :only => [:show]


  #----------------------------------------------------------------------------
  # GET /neighborhoods/1

  def show
    @post = Post.new

    # Calculate total metrics before we start filtering.
    @total_reports = @reports.count
    @total_points  = @neighborhood.total_points

    # Limit the activity feed to *current* neighborhood members.
    user_ids = @users.pluck(:id)
    @reports = @reports.displayable.completed
    @reports = @reports.where("reporter_id IN (?) OR verifier_id IN (?) OR resolved_verifier_id IN (?) OR eliminator_id IN (?)", user_ids, user_ids, user_ids, user_ids)
    @reports = @reports.order("created_at DESC")

    @posts   = @neighborhood.posts.where(:user_id => user_ids).order("updated_at DESC").includes(:comments)

    # Limit the amount of records we show.
    unless params[:feed].to_s == "1"
      @posts   = @posts.limit(20)
      @reports = @reports.limit(10)
    end

    @activity_feed = @notices.to_a + @posts.to_a

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

  def calculate_ivars
    # Load associations.
    @neighborhood = Neighborhood.find(params[:id])
    @users   = @neighborhood.users.where(:is_blocked => false).order("first_name ASC")
    @teams   = @neighborhood.teams.order("name ASC")
    @reports = @neighborhood.reports
    @notices = @neighborhood.notices.order("updated_at DESC").where("date > ?", Time.zone.now.beginning_of_day)
  end

end
