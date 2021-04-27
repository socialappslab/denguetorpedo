# -*- encoding : utf-8 -*-

class Dashboard::SettingsController < Dashboard::BaseController
  after_action :verify_authorized, except: [:create, :organizations_select, :users_select]
  #----------------------------------------------------------------------------
  # GET /dashboard/settings

  def index
    authorize :dashboard, :index?
    @city = current_user.city
  end

  def create
    if params[:organizations_select].blank?
      redirect_to dashboard_settings_path, :flash => { :alert => I18n.t("views.dashboard.failed_create_flash") } and return
    end

    if !params[:dataVisits].blank?
      @parameters = Parameter.where(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url')
      if @parameters.blank?
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.visits.url' , :value => params[:dataVisits])
        dataVisits.save
      else
        @parameters.first.update_column(:value, params[:dataVisits])
      end
    end

    if !params[:dataLocations].blank?
      @parameters = Parameter.where(:organization_id => params[:organizations_select], :key => 'organization.data.locations.url')
      if @parameters.blank?
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.locations.url' , :value => params[:dataLocations])
        dataVisits.save
      else
        @parameters.first.update_column(:value, params[:dataLocations])
      end
    end

    if !params[:datainspections].blank?
      @parameters = Parameter.where(:organization_id => params[:organizations_select], :key => 'organization.data.inspections.url')
      if @parameters.blank?
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.data.inspections.url' , :value => params[:datainspections])
        dataVisits.save
      else
        @parameters.first.update_column(:value, params[:datainspections])
      end
    end

    if !params[:volunteers].blank?
      @parameters = Parameter.where(:organization_id => params[:organizations_select], :key => 'organization.sync.default-user')
      @user_params = User.find_by_id(params[:volunteers])
      if @parameters.blank?
        dataVisits = Parameter.new(:organization_id => params[:organizations_select], :key => 'organization.sync.default-user' , :value => @user_params.username)
        dataVisits.save
      else
        @parameters.first.update_column(:value, @user_params.username)
      end
    end
    redirect_to dashboard_settings_path, :flash => { :notice => I18n.t("views.dashboard.success_create_flash") } and return

  end

  def value_exist(parameter,value)
      if parameter.key == value
        return true
      end
    return false
  end

  def organizations_select
    @select = Parameter.where(:organization_id => params[:id])
    render json: @select.to_json, status:200
  end

  def users_select
    @select = User.select("id", "first_name", "last_name", "name").where(:username => params[:username])
    render json: @select.to_json, status:200
  end

end
#----------------------------------------------------------------------------

