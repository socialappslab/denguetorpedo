# -*- encoding : utf-8 -*-

class Coordinator::TeamsController < Coordinator::BaseController
  #----------------------------------------------------------------------------
  # GET /coordinator/teams

  def index
    authorize! :edit, Team

    @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )

    if @neighborhood.present?
      @teams = Team.where(:neighborhood_id => @neighborhood.id).order("name ASC")
    else
      @teams = Team.order("name ASC").all
    end

    @breadcrumbs << {:name => I18n.t("views.coordinator.manage_teams"), :path => coordinator_teams_path}
  end

  #----------------------------------------------------------------------------
  # GET /coordinator/teams/:id/block

  def block
    # TODO: Change to the appropriate policy.
    authorize! :edit, Team

    @team         = Team.find(params[:id])
    @team.blocked = !@team.blocked

    if @team.save!
      notice = (@team.blocked ? I18n.t("views.admin.team_successfully_blocked") : I18n.t("views.admin.team_successfully_unblocked"))

      flash[:notice] = notice
      redirect_to coordinator_teams_path and return
    else
      flash[:alert] = I18n.t("views.application.error")
      redirect_to coordinator_teams_path and return
    end
  end

  #----------------------------------------------------------------------------
end
