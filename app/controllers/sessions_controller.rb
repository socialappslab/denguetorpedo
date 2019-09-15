# -*- encoding : utf-8 -*-
class SessionsController < ApplicationController

  def new
  end

  #----------------------------------------------------------------------------

  def create
    user = User.find_by_username( params[:username].downcase )

    # Try to identify the user by email if username fails. This is because we
    # used to require login by email, but moved over to usernames.
    user = User.find_by_email( params[:username].downcase ) if user.nil?

    # Try to identify the user by name if username/email fails. This is because
    # we moved to using Twitter-like usernames.
    user = User.find_by_name( params[:username].downcase ) if user.nil?

    if user && user.authenticate(params[:password].downcase)
      if user.is_blocked == true
        redirect_to root_url, :alert => I18n.t("views.application.user_blocked") and return
      end

      cookies.permanent[:auth_token] = user.auth_token
      respond_to do |format|
        # NOTE: We're disabling showing a notice per conversation between
        # @dman7 and @jamesholston
        # "The folks in Brazil did not like the green banners saying logged in and logged out.
        # It's not a question of Portuguese.  This is what banking and other commercial
        # sites do and they did not want that association.
        # So let's remove it for now until we have more time to look into the question.
        # Can you just bracket it rather than delete it?"
        format.html { redirect_to city_path(user.city) }
        format.json { render json: {auth_token: user.auth_token}}
      end
    else
      redirect_to root_url, :alert => I18n.t("views.flashes.login.error")
    end
  end

  #----------------------------------------------------------------------------

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_url
  end

  #----------------------------------------------------------------------------

end
