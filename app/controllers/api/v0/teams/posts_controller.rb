# -*- encoding : utf-8 -*-
class API::V0::Teams::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter      :current_user

  #----------------------------------------------------------------------------
  # GET /api/v0/teams/:id/posts
  #------------------------------------

  def index
    @team    = Team.find(params[:team_id])
    user_ids = @team.users.pluck(:id)
    @posts   = Post.where(:user_id => user_ids).order("created_at DESC").includes(:comments)

    if params[:limit].present?
     @posts = @posts.limit(params[:limit].to_i)
    end

    if params[:offset].present?
     @posts = @posts.offset(params[:offset].to_i)
    end

    render "api/v0/posts/index" and return
  end

  #----------------------------------------------------------------------------
end
