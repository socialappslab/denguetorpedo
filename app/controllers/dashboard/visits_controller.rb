# -*- encoding : utf-8 -*-

class Dashboard::VisitsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/visits

  def index
    authorize :dashboard, :index?
    @city = @current_user.city
  end

  #----------------------------------------------------------------------------

end
