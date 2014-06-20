# encoding: utf-8
class TeamsController < NeighborhoodsBaseController
  before_filter :require_login

  def index
    @teams = Team.all
  end
end
