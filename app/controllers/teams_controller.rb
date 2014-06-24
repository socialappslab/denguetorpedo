# encoding: utf-8
class TeamsController < NeighborhoodsBaseController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /teams

  def index
    @teams = Team.all
  end

  #----------------------------------------------------------------------------
  # GET /teams/1

  def show
    @team = Team.find(params[:id])
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/join

  def join
    @team = Team.find(params[:id])

    team_membership = TeamMembership.new(:user_id => @current_user.id, :team_id => @team.id, :verified => false)

    if team_membership.save
      redirect_to teams_path and return
    else
      @teams = Team.all

      flash[:alert] = I18n.t("common_terms.something_went_wrong")
      render "teams/index" and return
    end
  end

  #----------------------------------------------------------------------------
end
