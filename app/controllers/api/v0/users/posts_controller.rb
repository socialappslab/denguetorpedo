# -*- encoding : utf-8 -*-
class API::V0::Users::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user

  #----------------------------------------------------------------------------
  # GET /api/v0/users/:id/posts
  #------------------------------------

  def index
    @user = User.find(params[:user_id])
    @posts = @user.posts.order("created_at DESC").includes(:comments)
    render "api/v0/posts/index" and return
  end
end
