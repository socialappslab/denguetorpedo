# -*- encoding : utf-8 -*-

class Coordinator::UsersController < Coordinator::BaseController
  #----------------------------------------------------------------------------
  # GET /coordinator/users/new

  def new
    # TODO
    # authorize! :edit, User.new
    @user ||= User.new
  end

  #----------------------------------------------------------------------------
  # POST /coordinator/users

  def create
    # TODO
    # authorize! :edit, User



    @user = User.new(params[:user])
    if @user.save!
      redirect_to edit_user_path(@current_user), :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash")}
    else
      render "coordinator/users/new", flash: { alert: @user.errors.full_messages.join(', ')}
    end
  end

  #----------------------------------------------------------------------------

end
