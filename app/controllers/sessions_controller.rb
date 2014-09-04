# encoding: utf-8
class SessionsController < ApplicationController

  def new
  end

  #----------------------------------------------------------------------------

  def create
    user = User.find_by_username( params[:username] )

    if user && user.authenticate(params[:password])

      if user.is_blocked == false
        if params[:remember_me]
          cookies.permanent[:auth_token] = user.auth_token
        else
          cookies[:auth_token] = user.auth_token
        end

        respond_to do |format|
          # NOTE: We're disabling showing a notice per conversation between
          # @dman7 and @jamesholston
          # "The folks in Brazil did not like the green banners saying logged in and logged out.
          # It's not a question of Portuguese.  This is what banking and other commercial
          # sites do and they did not want that association.
          # So let's remove it for now until we have more time to look into the question.
          # Can you just bracket it rather than delete it?"
          format.html { redirect_to user_path(user) }
          format.json { render json: {auth_token: user.auth_token}}
        end
      else
        redirect_to root_url, :alert => I18n.t("views.application.user_blocked")
      end

    else
      redirect_to root_url, :alert => I18n.t("common_terms.email_or_password_incorrect")
    end
  end

  #----------------------------------------------------------------------------

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_url
  end

  #----------------------------------------------------------------------------

end
