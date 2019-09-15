# -*- encoding : utf-8 -*-

class Coordinator::UsersController < Coordinator::BaseController
  #----------------------------------------------------------------------------
  # GET /coordinator/users

  # def index
  #   authorize! :assign_roles, User
  #
  #   @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )
  #   @users        = User.order("username ASC")
  #
  #   @users = @users.where(:neighborhood_id => @neighborhood.id) if @neighborhood.present?
  #
  #   @breadcrumbs << {:name => I18n.t("views.coordinator.manage_users"), :path => coordinator_users_path}
  # end

  #----------------------------------------------------------------------------
  # GET /coordinator/users/:id/block

  def block
    # TODO: Change to appropriate policy.
    authorize! :assign_roles, User

    @user = User.find(params[:id])
    @user.is_blocked = !@user.is_blocked
    if @user.save
      if @user.is_blocked
        redirect_to coordinator_users_path, notice: "Usuário bloqueado com sucesso."
      else
        redirect_to coordinator_users_path, notice: "Usuário desbloqueado com sucesso."
      end
    else
      redirect_to coordinator_users_path, notice: "There was an error blocking the user"
    end
  end

  #----------------------------------------------------------------------------
  # GET /coordinator/users/new

  def new
    authorize! :edit, User.new
    @user ||= User.new

    @breadcrumbs << {:name => I18n.t("views.coordinator.register_user"), :path => new_coordinator_user_path}
  end

  #----------------------------------------------------------------------------
  # POST /coordinator/users

  def create
    authorize! :edit, User

    @user = User.new(params[:user])
    @user.username.downcase

    if @user.save
      redirect_to coordinator_users_path, :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash")} and return
    else
      render "coordinator/users/new", flash: { alert: @user.errors.full_messages.join(', ')}
    end
  end

  #----------------------------------------------------------------------------



end
