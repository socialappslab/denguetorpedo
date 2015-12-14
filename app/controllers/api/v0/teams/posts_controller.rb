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

    if params[:hashtag].present?
      pids = Hashtag.post_ids_for_hashtag(params[:hashtag])
      @posts = @posts.where(:id => pids)
    end

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
