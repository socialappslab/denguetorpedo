# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @neighborhoods_select = Neighborhood.order("name ASC").map {|n| [n.name, n.id]}
    @city = current_user.city
  end

end
#----------------------------------------------------------------------------

