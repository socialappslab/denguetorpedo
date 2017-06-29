# -*- encoding : utf-8 -*-
class API::V0::UsersController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token, :only => [:index, :create, :membership, :update, :scores]
  before_filter :authenticate_user_via_cookies_or_jwt,    :only => [:update]
  before_action :calculate_header_variables

  #----------------------------------------------------------------------------
  # GET /api/v0/users/

  def index
    @organization = current_user.selected_membership.organization
    @memberships  = @organization.memberships.includes(:user).order("user_id")

    if params[:city_id].present?
      nids = Neighborhood.where(:city_id => params[:city_id]).pluck(:id)
      uids = User.where(:neighborhood_id => nids).pluck(:id)
      @memberships = @memberships.where(:user_id => uids)
    end

    if params[:neighborhood_id].present?
      uids = User.where(:neighborhood_id => params[:neighborhood_id]).pluck(:id)
      @memberships = @memberships.where(:user_id => uids)
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/memberships

  def membership
    @organization = current_user.selected_membership.organization
    authorize @organization

    @membership = @organization.memberships.find_by(:id => params[:id])
    @membership.role = params[:membership][:role]
    if @membership.save
      render :json => {}, :status => :ok and return
    else
      raise API::V0::Error.new("Something went wrong!", 422) and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/users

  def create
    @organization = current_user.selected_membership.organization

    # At this point, the user does NOT exist. Let's create them here.
    @user          = User.new(params[:user])
    @user.password = "1234567"
    if @user.save
      Membership.create(:user_id => @user.id, :organization_id => @organization.id, :role => Membership::Roles::RESIDENT, :active => true)

      render :json => {}, :status => :ok and return
    else
      raise API::V0::Error.new(@user.errors.full_messages[0], 422) and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /api/v0/users/:id

  def update
    @current_user.name            = params[:user][:name]
    @current_user.email           = params[:user][:email]
    @current_user.username        = params[:user][:username]
    @current_user.neighborhood_id = params[:user][:neighborhood_id]
    if @current_user.save
      render :json => {}, :status => :ok and return
    else
      raise API::V0::Error.new(@current_user.errors.full_messages[0], 422) and return
    end
  end


  #----------------------------------------------------------------------------
  # GET /api/v0/users/:id/scores

  def scores
    @user = User.find_by_id(params[:user_id])
    @report_count = @user.reports.completed.count
    @green_location_ranking = GreenLocationRankings.score_for_user(@user).to_i

    render :json => {:points => @user.total_total_points, :report_count => @report_count, :green_location_ranking => @green_location_ranking}, :status => :ok and return
  end

  #----------------------------------------------------------------------------
end
