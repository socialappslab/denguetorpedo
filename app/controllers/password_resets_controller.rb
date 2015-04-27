# -*- encoding : utf-8 -*-

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
      redirect_to root_url, :notice => I18n.t("views.password_resets.create.reset_email_sent")
    else
      flash[:alert] = I18n.t("views.application.email_invalid")
      redirect_to new_password_reset_path
    end
  end

  #----------------------------------------------------------------------------
  # GET /password_resets/:id/edit

  def edit
    @user   = User.find_by_password_reset_token(params[:id])
    @user ||= User.find_by_id(params[:id])

    if @user.blank?
      flash[:alert] = I18n.t("views.password_resets.does_not_exist")
      redirect_to root_path and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /password_resets/:id

  def update
    @user   = User.find_by_password_reset_token(params[:id])
    @user ||= User.find_by_id(params[:id])

    if @user.update_attributes(params[:user])
      flash[:notice] = I18n.t("views.password_resets.update.success")
      redirect_to root_path and return
    else
      render "edit" and return
    end

  end

  #----------------------------------------------------------------------------

end
