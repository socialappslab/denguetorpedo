class NeighborhoodsBaseController < ApplicationController
  before_filter :identify_neighborhood
  before_filter :ensure_team_chosen

  #----------------------------------------------------------------------------

  def identify_neighborhood
    @neighborhood = Neighborhood.find_by_id(params[:neighborhood_id])
  end

  #----------------------------------------------------------------------------

  def ensure_team_chosen
    if @current_user && @current_user.teams.count == 0
      flash[:notice] = I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    end
  end

  #----------------------------------------------------------------------------

end
