# -*- encoding : utf-8 -*-
class API::V0::UsersController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
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

    @user = User.find_by(:username => params[:user][:username])
    if @user.present?
      raise API::V0::Error.new("Usuario con nombre de usuario #{params[:user][:username]} ya existe!", 422) and return
    end

    # At this point, the user does NOT exist. Let's create them here.
    @user          = User.new(params[:user])
    @user.password = "1234567"
    Membership.create(:user_id => @user.id, :organization_id => @organization.id, :active => true)

    if @user.save
      render :json => {}, :status => :ok and return
    else
      raise API::V0::Error.new("Something went wrong!", 422) and return
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
