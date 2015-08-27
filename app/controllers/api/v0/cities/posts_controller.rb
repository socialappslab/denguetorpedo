# -*- encoding : utf-8 -*-
class API::V0::Cities::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter      :current_user

  #----------------------------------------------------------------------------
  # GET /api/v0/cities/:city_id/posts
  #------------------------------------

  def index
    @city  = City.find(params[:city_id])

    nids = @city.neighborhoods.pluck(:id)
    @posts = Post.where(:neighborhood_id => nids).order("posts.created_at DESC")

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

  #----------------------------------------------------------------------------
end
