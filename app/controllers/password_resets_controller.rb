# encoding: utf-8

class PasswordResetsController < ApplicationController

  #----------------------------------------------------------------------------
  # GET /password_resets/new

  def new
  end

  #----------------------------------------------------------------------------
  # POST /password_resets

  def create
    @user = User.find_by_email(params[:email])

    if @user
      @user.send_password_reset
      redirect_to root_url, :alert => I18n.t("views.password_resets.create.reset_email_sent")
    else
      flash[:alert] = I18n.t("views.application.email_invalid")
      redirect_to new_password_reset_path
    end
  end

  #----------------------------------------------------------------------------
  # GET /password_resets/:id/edit

  def edit
    @user = User.find_by_password_reset_token(params[:id])

    if @user.blank?
      flash[:alert] = I18n.t("views.password_resets.does_not_exist")
      redirect_to root_path and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /password_resets

  def update
    if params[:user][:current_password]
      if @current_user.authenticate(params[:user][:current_password])
        if params[:user][:password] != params[:user][:password_confirmation]
          flash[:alert] = "Password and password confirmation do not match."
          redirect_to :back
          return
        end
        if @current_user.update_attributes(params[:user])
          flash[:notice] = "A senha foi alterada! "
          redirect_to edit_user_path(@current_user)
        else
          flash[:alert] = "There was an error updating your password."
          redirect_to edit_user_path(@current_user)
        end
      else
        flash[:alert] = "You have entered a wrong password."
        redirect_to :back
      end
    else
      @user = User.find_by_password_reset_token!(params[:id])
      if @user.update_attributes(params[:user])
        flash[:notice] = "A senha foi alterada!"
        redirect_to root_url
      else
        flash[:alert] = "There was an error updating your password."
        redirect_to root_url
      end
    end
  end

  #----------------------------------------------------------------------------

end
