# encoding: utf-8
class SessionsController < ApplicationController

  def new
  end

  def create
    user = User.find_by_email(params[:email])

    if user && user.authenticate(params[:password])

      if user.is_blocked == false
        if params[:remember_me]
          cookies.permanent[:auth_token] = user.auth_token
        else
          cookies[:auth_token] = user.auth_token
        end
        respond_to do |format|
          format.html { redirect_to root_url, :notice => "Você está logado!"}
          format.json { render json: {auth_token: user.auth_token}}
        end
      else
        redirect_to root_url, :alert => "Sua conta está bloqueada temporariamente.  Por favor, entre em contato com o Dengue Torpedo."
      end
    else
      redirect_to root_url, :alert => "Invalid email or password."
    end
  end

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_url, :notice => "Você saiu da sua conta!"
  end

end
