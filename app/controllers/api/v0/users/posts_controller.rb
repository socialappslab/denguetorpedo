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

    if params[:limit].present?
     @posts = @posts.limit(params[:limit].to_i)
    end

    if params[:offset].present?
     @posts = @posts.offset(params[:offset].to_i)
    end

    if @current_user.present?
      likes               = @current_user.likes
      @user_post_likes    = likes.where(:likeable_type => Post.name).pluck(:likeable_id)
      @user_comment_likes = likes.where(:likeable_type => Comment.name).pluck(:likeable_id)
    end

    render "api/v0/posts/index" and return
  end
end
