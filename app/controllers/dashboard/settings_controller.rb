# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end
  def create
    @settings = Parameter.new(params[:settings])
    if @settings.save
      render json: @settings.to_json, status: 200
    else
      raise API::V0::Error.new(@settings.errors.full_messages[0], 422)
    end
  end
end
#----------------------------------------------------------------------------

