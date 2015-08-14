# -*- encoding : utf-8 -*-
class API::V0::Neighborhoods::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter      :current_user

  #----------------------------------------------------------------------------
  # GET /api/v0/neighborhoods/:id/posts
  #------------------------------------

  def index
    @neighborhood = Neighborhood.find(params[:neighborhood_id])
    @posts = @neighborhood.posts.order("created_at DESC").includes(:comments)

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
