# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end
  def create
    @logger.info "create"
    Rails.logger.info(params[:organization_id])
    dataVisits = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
    dataLocations = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.locations.url' , :value => params[:dataLocations])
    datainspections = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.inspections.url' , :value => params[:datainspections])
    volunteers = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.sync.default-user' , :value => params[:volunteers])
    @logger.info dataVisits
    dataVisits.save
    dataLocations.save
    datainspections.save
    volunteers.save




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

