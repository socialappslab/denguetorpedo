# encoding: utf-8
class TeamsController < NeighborhoodsBaseController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /teams

  def index
    @teams = Team.all
    @team  = Team.new

    # Calculate ranking for each team.
    team_rankings  = @teams.map {|t| [t, t.total_points]}
    @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse
  end

  #----------------------------------------------------------------------------
  # GET /teams/1

  def show
    @team  = Team.find(params[:id])
    @users = @team.users
    @total_points  = @team.total_points
    @total_reports = @team.total_reports

    @post = Post.new

    # Load up posts from team's users.
    @posts = []
    @team.users.includes(:posts).each do |user|
      @posts << user.posts
    end
    @posts.flatten!

    @news_feed = @posts.to_a.sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # POST /teams

  def create
    @team = Team.new(params[:team])

    # TODO: I'm not happy with assigning default neighborhood for a team,
    # but this is the state of things for the time being. Consider moving
    # away from neighborhood specific things...?
    @team.neighborhood_id = Neighborhood.find_by_name("Maré").id

    if @team.save
      # If the team was successfully created, create the team membership
      # since any user who creates a team must be interested in joining it,
      # automatically.
      TeamMembership.create(:team_id => @team.id, :user_id => @current_user.id, :verified => true)
      flash[:notice] = I18n.t("views.teams.success_create_flash")
      redirect_to teams_path and return
    else
      @teams = Team.all

      # Calculate ranking for each team.
      team_rankings  = @teams.map {|t| [t, t.total_points]}
      @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse

      # Let's simplify the user's life by displaying the form in case of failure.
      # After all, if we've reached this point, then the user's last interaction
      # was with the new team form.
      flash[:show_new_team_form] = true
      render "index" and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/join

  def join
    @team = Team.find(params[:id])

    team_membership = TeamMembership.new(:user_id => @current_user.id, :team_id => @team.id, :verified => false)

    if team_membership.save
      flash[:notice] = I18n.t("views.teams.success_join_flash")
      redirect_to teams_path and return
    else
      @teams = Team.all

      flash[:alert] = I18n.t("views.application.error")
      render "teams/index" and return
    end
  end

  #----------------------------------------------------------------------------
end
