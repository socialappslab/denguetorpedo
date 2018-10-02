# -*- encoding : utf-8 -*-
class TeamsController < ApplicationController
  before_filter :require_login
  before_filter :identify_neighborhood,            :except => [:administer]
  before_filter :ensure_proper_permissions, :only => [:administer, :block]
  before_filter :update_breadcrumb
  before_action :calculate_header_variables
  respond_to :html, :json
  skip_before_filter :require_login, :only => [:show, :index]
  skip_before_filter :identify_neighborhood, :only => [:show, :index]

  #----------------------------------------------------------------------------
  # GET /teams

  def index

    if @current_user.present?
      @teams = current_user.selected_membership.organization.teams.where(:neighborhood_id => @neighborhood.id).where(:blocked => [nil, false])
    else
      @teams = Team.where(:blocked => [nil, false])
    end

    # Calculate ranking for each team.
    if params[:sort].present? && params[:sort].downcase == "name"
      @team_rankings = @teams.order("name").map {|t| [t, t.points]}
    else
      team_rankings  = @teams.map {|t| [t, t.points]}
      @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse
    end

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited teams page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited teams page", :properties => {:neighborhood => @neighborhood.name}) if Rails.env.production?
    end
    respond_with @team_rankings
  end

  #----------------------------------------------------------------------------
  # GET /teams/1

  def show
    @post = Post.new

    # Load associations.
    # NOTE: We're going to bypass ActiveRecord association methods and instead
    # use custom AR chaining because we want to
    # a) control what kind of content shows up in the feed,
    # b) avoid existing inefficiencies in User model (e.g. see reports method in user.rb)
    @team    = Team.find(params[:id])
    @users   = @team.users
    user_ids = @users.pluck(:id)

    @reports = Report.where("reporter_id IN (?) OR eliminator_id IN (?)", user_ids, user_ids)
    @reports = @reports.displayable.completed

    @total_reports = @reports.count
    @total_points  = @team.points

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited a team page", :properties => {:team => @team.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited a team page", :properties => {:team => @team.name}) if Rails.env.production?
    end

    @breadcrumbs << {:name => @team.name, :path => team_path(@team)}
    respond_with @team
  end


  #----------------------------------------------------------------------------
  # POST /teams

  def create
    @team                 = Team.new(params[:team])
    @team.neighborhood_id = @neighborhood.id
    @team.organization_id = current_user.selected_membership.organization_id
    
    base64_image = params[:team][:compressed_photo]
    if base64_image.present?
      filename            = "team_profile_photo.jpg"
      paperclip_image     = prepare_base64_image_for_paperclip(base64_image, filename)
      @team.profile_photo = paperclip_image
    end

    if @team.save
      # If the team was successfully created, create the team membership
      # since any user who creates a team must be interested in joining it,
      # automatically.
      TeamMembership.create(:team_id => @team.id, :user_id => @current_user.id, :verified => true)
      flash[:notice] = I18n.t("views.teams.success_create_flash")

      Analytics.track( :user_id => @current_user.id, :event => "Created a team", :properties => {:neighborhood => @neighborhood.name} ) if Rails.env.production?


      respond_to do |format|
        format.html { redirect_to teams_path and return }
        format.json { render :json => {:team => @team, :success => flash[:notice]}, :status => :ok }
      end
    else
      @teams = Team.where(:neighborhood_id => @neighborhood.id).where(:blocked => [nil, false])

      # Calculate ranking for each team.
      team_rankings  = @teams.map {|t| [t, t.points]}
      @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse

      # Let's simplify the user's life by displaying the form in case of failure.
      # After all, if we've reached this point, then the user's last interaction
      # was with the new team form.
      respond_to do |format|
        format.html {
          flash[:show_new_team_form] = true
          render "index" and return
        }
        format.json { render :json => {:errors => @team.errors.full_messages} , :status => :ok }
      end
    end
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/join

  def join
    @team         = Team.find( params[:id] )
    membership = TeamMembership.find_or_create_by(:user_id => @current_user.id, :team_id => @team.id)
    if membership.save
      flash[:notice] = I18n.t("views.teams.success_join_flash")
      redirect_to :back and return
    else
      @teams = Team.all

      flash[:alert] = I18n.t("views.application.error")
      render "teams/index" and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/leave

  def leave
    membership = @current_user.team_memberships.find { |tm| tm.team_id.to_s == params[:id].to_s }

    respond_to do |format|
      if membership && membership.destroy
        flash[:notice] = I18n.t("views.teams.success_leave_flash")

        format.html { redirect_to :back and return }
        format.json { render :json => :ok and return }
      else
        flash[:alert] = I18n.t("views.application.error")

        format.html { redirect_to :back and return }
        format.json { render :json => :bad_request and return }
      end
    end
  end

  #----------------------------------------------------------------------------

  private

  def identify_neighborhood
    @neighborhood = @current_user.neighborhood
  end

  def update_breadcrumb
    @breadcrumbs << {:name => I18n.t("activerecord.models.team", :count => 2), :path => teams_path}
  end

  #----------------------------------------------------------------------------

end
