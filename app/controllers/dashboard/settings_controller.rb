# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  after_action :verify_authorized, except: [:create, :organizations_select]
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end
  def create
    Rails.logger.info("PRUEBA 2-------------------||||")
    Rails.logger.info(params[:organizations_select])

    if params[:organizations_select].blank?
      redirect_to dashboard_settings_path, :flash => { :alert => "Debe seleccionar una organización" } and return
    end

    if !params[:dataVisits].blank?
      @visits = Parameter.where(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url')
      Rails.logger.info("visita------------------||||")
      Rails.logger.info(!@visits.blank?)
      if @visits.blank?
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
        dataVisits.save
      else
        dataVisits = @visits.update_column(:value, params[:dataVisits])
        dataVisits.save
      end
    end

=begin
    @parameter_value = Parameter.where(:organization_id => params[:organizations_select])
    @parameter_value.each do |row|
      if value_exist(row,'organization.data.visits.url' )
        Rails.logger.info("ya merito")
        Rails.logger.info(row)
        dataVisits = row.update_column(:value, params[:dataVisits])
        Rails.logger.info(dataVisits)
      else
        Rails.logger.info("va ser create")
        Rails.logger.info(row)
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
        dataVisits.save
      end
    end
=end

=begin
    dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
    dataLocations = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.locations.url' , :value => params[:dataLocations])
    datainspections = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.inspections.url' , :value => params[:datainspections])
    @user_params = User.find_by_id(params[:volunteers])
    Rails.logger.info(@user_params.username)
    volunteers = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.sync.default-user' , :value => @user_params.username)

    dataVisits.save
    dataLocations.save
    datainspections.save
    volunteers.save

    if dataVisits.save && dataLocations.save && datainspections.save && volunteers.save
      redirect_to dashboard_settings_path, :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash") } and return
    else
      render dashboard_settings_path, flash: { alert: "ERROR" }
    end
=end
  end

  def value_exist(parameter,value)
    Rails.logger.info(parameter)
      if parameter.key == value
        return true
      end
    return false
  end

  def organizations_select
    @select = Parameter.where(:organization_id => params[:id])
    render json: @select.to_json, status:200

  end

end
#----------------------------------------------------------------------------

