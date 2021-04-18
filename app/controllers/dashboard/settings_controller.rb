# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  after_action :verify_authorized, except: [:create]
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end
  def create
    Rails.logger.info("PRUEBA 1-------------------||||")
    if params[:organization_id].blank?
      Rails.logger.info("PRUEBA 2-------------------||||")
      flash[:alert] = "Debe seleccionar una organización"
      redirect_to dashboard_settings_path and return

    end
    Rails.logger.info(params[:volunteers])
    dataVisits = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
    dataLocations = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.locations.url' , :value => params[:dataLocations])
    datainspections = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.data.inspections.url' , :value => params[:datainspections])
    @user_params = User.find_by_id(params[:volunteers])
    Rails.logger.info(@user_params.username)
    volunteers = Parameter.new(:organization_id => params[:organization_id], :key => 'organization.sync.default-user' , :value => @user_params.username)

    dataVisits.save
    dataLocations.save
    datainspections.save
    volunteers.save

=begin
    if dataVisits.save && dataLocations.save && datainspections.save && volunteers.save
      redirect_to dashboard_settings_path, :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash") } and return
    else
      render "coordinator/users/new", flash: { alert: @user.errors.full_messages.join(', ') }
    end
=end

  end

end
#----------------------------------------------------------------------------

