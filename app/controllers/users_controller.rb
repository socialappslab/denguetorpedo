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
    @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )

    @users     = User.residents.order("created_at DESC")
    @sponsors  = User.where(:role => User::Types::SPONSOR).order("created_at DESC")
    @verifiers = User.where(:role => User::Types::VERIFIER).order("created_at DESC")

    if @neighborhood.present?
      @users     = @users.where(:neighborhood_id => @neighborhood.id)
      @sponsors  = @sponsors.where(:neighborhood_id => @neighborhood.id)
      @verifiers = @verifiers.where(:neighborhood_id => @neighborhood.id)
    end

    authorize! :assign_roles, User

    respond_to do |format|
      format.html
      format.json { render json: { users: @users}}
    end
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
    @coupons           = @user.prize_codes.reject {|c| c.expired? }
    @prizes            = Prize.where('stock > 0').where(:is_badge => false).where('expire_on >= ? OR expire_on is NULL', Time.now)
    @redeemable_prizes = @prizes.where("cost <= ?", @user.total_points).shuffle

    # Build a feed depending on params.
    @posts  = @user.posts.order("updated_at DESC")
    if params[:feed].to_s == "1"
      @reports = @neighborhoods.map {|n| n.reports.order("updated_at DESC") }.flatten
      @notices = @neighborhoods.map {|n| n.notices.order("updated_at DESC") }.flatten
    else
      @posts   = @posts.limit(3)
      @reports = @neighborhoods.map {|n| n.reports.order("updated_at DESC").limit(5) }.flatten
      @notices = @neighborhoods.map {|n| n.notices.order("updated_at DESC").limit(5) }.flatten
    end

    @activity_feed  = (@posts.to_a + @reports.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
    @reports_by_user = @user.reports.where("completed_at IS NOT NULL")

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
    # NOTE: These horrendous actions are a result of trying to save form information,
    # even when later information may not be correct.
    @user.update_attribute(:gender, params[:user][:gender])
    @user.update_attribute(:neighborhood_id, params[:user][:neighborhood_id])
    @user.update_attribute(:first_name, params[:user][:first_name])
    @user.update_attribute(:last_name, params[:user][:last_name])
    @user.update_attribute(:nickname, params[:user][:nickname])
    @user.update_column(:locale, params[:user][:locale].to_s)

    base64_image = params[:user][:compressed_photo]
    if base64_image.present?
      filename            = @user.display_name.underscore + "_profile_photo.jpg"
      paperclip_image     = prepare_base64_image_for_paperclip(base64_image, filename)
      @user.profile_photo = paperclip_image
    end

    @user.update_attributes(params[:user].slice(:phone_number, :carrier, :prepaid)) if params[:cellphone] == "false"

    # TODO: Clean up and clarify the intent of this line.
    user_params = params[:user].slice(:profile_photo, :gender, :username, :email, :first_name, :last_name, :nickname, :neighborhood_id, :phone_number, :cellphone, :carrier, :prepaid)

    if @user.update_attributes(user_params)
      # Identify the recruiter for this user.
      recruiter = User.find_by_id( params[:recruiter_id] )
      if recruiter
        @user.recruiter = recruiter

        # Only add points to the recruiter if the user isn't fully registered.
        recruiter.total_points += 50 if @user.is_fully_registered == false


        recruiter.save
      end

      @user.update_attribute(:is_fully_registered, true)
    else
      render "edit" and return
    end

    redirect_to edit_user_path(@user), :flash => { :notice => I18n.t("views.users.edit.success_flash") }
  end


  #----------------------------------------------------------------------------

  def destroy
    @user = User.find(params[:id])

    # Destroy the user's house if he is the only one in the house.
    if @user.house && @user.house.members.count == 1
      @user.house.destroy
    end

    # Finally, let's delete the user.
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
