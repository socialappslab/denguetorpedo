# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController
  include GreenLocationRankings

  before_filter :require_login,             :only => [:edit, :update, :index, :show, :destroy]
  before_filter :ensure_team_chosen,        :only => [:show]
  before_filter :identify_user,             :only => [:edit, :update, :show]
  before_filter :ensure_proper_permissions, :only => [:index, :phones, :destroy]
  before_action :calculate_header_variables


  #----------------------------------------------------------------------------
  # POST /users/cookies

  # This action is responsible for setting cookie settings for a user.
  def set_neighborhood_cookie
    cookies[:neighborhood_id] = params[:neighborhood_id] if params[:neighborhood_id].present?
    redirect_to :back and return
  end

  #----------------------------------------------------------------------------
  # GET /users/switch

  # This action is responsible for setting cookie settings for a user.
  def switch
    @current_user.selected_membership.update_column(:active, false)
    @current_user.memberships.find_by(:id => params[:membership_id]).update_column(:active, true)

    redirect_to :back and return
  end


  #----------------------------------------------------------------------------
  # GET /users/1/

  def show
    redirect_to user_path(@current_user) and return if @user.blank?

    @city              = @user.city
    @neighborhoods     = @city.neighborhoods.includes(:city, :notices, :users)

    @post              = Post.new
    # @badges            = @user.badges
    @teams             = @user.teams
    @neighborhood      = @user.neighborhood
    @prizes            = Prize.where('stock > 0').where(:is_badge => false).where('expire_on >= ? OR expire_on is NULL', Time.zone.now)
    @redeemable_prizes = @prizes.where("cost <= ?", @user.total_points).shuffle

    # Build a feed depending on params.
    @report_count = @user.reports.completed.count

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited a user page", :properties => {:user => @user.id}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited a user page", :properties => {:user => @user.id}) if Rails.env.production?
    end

    @green_location_ranking = GreenLocationRankings.score_for_user(@user).to_i

    @breadcrumbs << {:name => @user.username, :path => user_path(@user)}
  end

  #----------------------------------------------------------------------------
  # GET /users/new

  def new
    @user = User.new

    @breadcrumbs << {:name => I18n.t("common_terms.register"), :path => new_user_path}
  end

  #----------------------------------------------------------------------------

  def create
    @user = User.new(params[:user])
    @user.username.downcase

    if params[:organization_id].blank?
      flash[:alert] = "Debe seleccionar una organización"
      render new_user_path(@user) and return
    end

    if @user.save
      # Set the default language based on selected neighborhood.
      if @user.neighborhood && @user.neighborhood.spanish?
        @user.update_column(:locale, User::Locales::SPANISH)
      else
        @user.update_column(:locale, User::Locales::PORTUGUESE)
      end

      Membership.create(:user_id => @user.id, :organization_id => params[:organization_id], :active => true)

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

    @breadcrumbs << {:name => I18n.t("common_terms.configuration"), :path => edit_user_path(@user)}
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
      redirect_to params[:redirect_path] || edit_user_path(@user), :flash => { :notice => I18n.t("views.users.edit.success_flash") }
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

  private

  #----------------------------------------------------------------------------

  def identify_user
    @user = User.find_by_id( params[:user_id] )
    @user = User.find( params[:id] ) if @user.blank?
  end

  #----------------------------------------------------------------------------
end
