#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController
  before_filter :require_login,             :only => [:edit, :update, :index, :show]
  before_filter :ensure_team_chosen,        :only => [:show]
  before_filter :identify_user,             :only => [:edit, :update, :show]
  before_filter :ensure_proper_permissions, :only => [:index, :phones]

  #----------------------------------------------------------------------------
  # GET /users/

  def index
    authorize! :assign_roles, User

    @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )
    @users        = User.order("username ASC")

    @users = @users.where(:neighborhood_id => @neighborhood.id) if @neighborhood.present?
  end

  #----------------------------------------------------------------------------
  # GET /phones

  def phones
    @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )

    if @neighborhood.present?
      @users = User.where(:neighborhood_id => @neighborhood.id)
    else
      @users = User.all
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/1/

  def show
    redirect_to user_path(@current_user) and return if @user.blank?

    @city              = @user.city
    @neighborhoods     = @city.neighborhoods.includes(:city, :notices, :users)

    @post              = Post.new
    @badges            = @user.badges
    @teams             = @user.teams
    @neighborhood      = @user.neighborhood
    @prizes            = Prize.where('stock > 0').where(:is_badge => false).where('expire_on >= ? OR expire_on is NULL', Time.now)
    @redeemable_prizes = @prizes.where("cost <= ?", @user.total_points).shuffle

    # Build a feed depending on params.
    @posts   = @user.posts.order("updated_at DESC")
    @reports = @user.reports.where("completed_at IS NOT NULL").order("updated_at DESC")
    @reports_by_user = @reports.where("completed_at IS NOT NULL")

    unless params[:feed].to_s == "1"
      @posts   = @posts.limit(3)
      @reports = @reports.limit(5)
    end

    @activity_feed = (@posts.to_a + @reports.to_a).sort{|a,b| b.created_at <=> a.created_at }

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited a user page", :properties => {:user => @user.id}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited a user page", :properties => {:user => @user.id}) if Rails.env.production?
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/new

  def new
    @user = User.new
  end

  #----------------------------------------------------------------------------

  # TODO: Move this into CoordinatorController. For now, we'll use this legacy
  # hack.
  def special_new
    authorize! :edit, User.new
    @user ||= User.new
    render "coordinators/users/edit" and return
  end

  #----------------------------------------------------------------------------

  def create
    params[:user].each{|key,val| params[:user][key] = params[:user][key].strip}

    @user = User.new(params[:user])
    if @user.save

      # Set the default language based on selected neighborhood.
      if @user.neighborhood && @user.neighborhood.spanish?
        @user.update_column(:locale, User::Locales::SPANISH)
      else
        @user.update_column(:locale, User::Locales::PORTUGUESE)
      end

      cookies[:auth_token] = @user.auth_token
      flash[:notice] = I18n.t("views.users.create_success_flash") + " " + I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    else
      render new_user_path(@user)
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/1/edit

  def edit
    authorize!(:edit, @user) if @user != @current_user

    @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
    @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}
  end

  #----------------------------------------------------------------------------
  # PUT /users/1

  def update
    if params[:user][:password].blank?
      params[:user].except!(:password, :password_confirmation)
    end

    base64_image = params[:user][:compressed_photo]
    if base64_image.present?
      filename            = @user.display_name.underscore + "_profile_photo.jpg"
      paperclip_image     = prepare_base64_image_for_paperclip(base64_image, filename)
      @user.profile_photo = paperclip_image
    end

    if @user.update_attributes(params[:user])
      if recruiter = User.find_by_id( params[:recruiter_id] ) && @user.is_fully_registered != true
        @user.recruiter = recruiter
        recruiter.save
      end

      @user.update_column(:is_fully_registered, true) unless @user.is_fully_registered == true
      redirect_to edit_user_path(@user), :flash => { :notice => I18n.t("views.users.edit.success_flash") }
    else
      render "edit" and return
    end
  end


  #----------------------------------------------------------------------------

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    redirect_to users_url, :notice => "Usuário deletado com sucesso." and return
  end

  #----------------------------------------------------------------------------
  # GET /users/1/buy_prize/1

  def buy_prize
    @user       = User.find(params[:id])
    @prize      = Prize.find(params[:prize_id])
    @prize_code = @user.generate_coupon_for_prize(@prize)
    render :partial => "prizes/prizeconfirmation", :locals => {:bought => @prize_code.present?}
  end

  #----------------------------------------------------------------------------

  def special_create
    authorize! :edit, User

    @user = User.new(params[:user])
    if @user.save
      redirect_to coordinator_create_users_path, :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash")}
    else
      render "coordinators/users/edit", flash: { alert: @user.errors.full_messages.join(', ')}
    end
  end

  #----------------------------------------------------------------------------

  def block
    @user = User.find(params[:id])
    @user.is_blocked = !@user.is_blocked
    if @user.save
      if @user.is_blocked
        redirect_to users_path, notice: "Usuário bloqueado com sucesso."
      else
        redirect_to users_path, notice: "Usuário desbloqueado com sucesso."
      end
    else
      redirect_to users_path, notice: "There was an error blocking the user"
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def identify_user
    @user = User.find_by_id( params[:user_id] )
    @user = User.find( params[:id] ) if @user.blank?
  end

  #----------------------------------------------------------------------------
end
