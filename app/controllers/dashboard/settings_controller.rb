# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end
  def create
    Rails.logger.info("Hola2")
    object = Parameter.new(:organization_id => 5, :key => 'organization.data.visits.url' , :value => params[:dataVisits])
    @logger.info object
    object.save


=begin
    Rails.logger.info(params[:dataVisits])
    Rails.logger.info(params[:dataLocations])

    @parameter = Parameter.new

    @parameter.organization_id =
    @parameter.key =
    @parameter.value= "cdew"

    Rails.logger.info("Hola3")
    if @parameter.save
      render json: @parameter.to_json, status: 200
    else
      raise DASHBOARD::Error.new(@assignment.errors.full_messages[0], 422)
    end
=end


  end
end
#----------------------------------------------------------------------------

