# -*- encoding : utf-8 -*-
class API::V0::PostsController < API::V0::BaseController
  skip_before_action :authenticate_user_via_device_token

  # NOTE: We're starting to blend API calls from mobile and web which is why
  # we have to start checking for cookies[:auth_token] or JWT.
  before_action :current_user, :except => [:index]
  before_action :authenticate_user_via_cookies_or_jwt, :only => [:index]

  #----------------------------------------------------------------------------
  # GET api/v0/posts

  def index
    if params[:team_id].present?
      team     = Team.find(params[:team_id])
      user_ids = team.users.pluck(:id)
      @posts   = Post.where(:user_id => user_ids).order("created_at DESC").includes(:comments)
    elsif params[:city_id].present?
      city   = City.find(params[:city_id])
      nids   = city.neighborhoods.pluck(:id)
      @posts = Post.where(:neighborhood_id => nids).order("posts.created_at DESC")
    elsif params[:neighborhood_id].present?
      ngbrhd = Neighborhood.find(params[:neighborhood_id])
      @posts = ngbrhd.posts.order("created_at DESC").includes(:comments)
    end

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
  # POST api/v0/posts/:id/like

  def like
    @post = Post.find(params[:id])
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 and return if (@post.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @post.likes.find {|like| like.user_id == @current_user.id }
    if existing_like.present?
      existing_like.destroy
      count -= 1
      liked  = false
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @post.id, :likeable_type => Post.name)
      count += 1
      liked  = true

      Analytics.track( :user_id => @current_user.id, :event => "Liked a post", :properties => {:post => @post.id}) if Rails.env.production?
    end

    render :json => {'count' => count.to_s, "liked" => liked} and return
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/posts/:id

  def show
    @post = Post.find(params[:id])
    render "api/v0/posts/show" and return
  end

  #----------------------------------------------------------------------------
  # POST /api/v0/posts

  def create
    @post                 = Post.new(params[:post])
    @post.user_id         = @current_user.id
    @post.neighborhood_id = Neighborhood.find(params[:post][:neighborhood_id]).id

    base64_image = params[:post][:compressed_photo]
    if base64_image.present?
      filename             = @current_user.display_name.underscore + "_post_photo.jpg"
      paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
      @post.photo = paperclip_image
    end

    # Iterate over the content, identifying mentions by @, and then wrapping
    # the valid usernames with <a> HTML tag.
    mentioned_users = []
    @post.content.scan(/@\w*/).each do |mention|
      u = User.find_by_username( mention.gsub("@","") )

      if u.present?
        @post.content.gsub!(mention, "<a href='#{user_path(u)}'>#{mention}</a>")
        mentioned_users << u
      end
    end

    if @post.save
      # Now that we know the post is valid, let's go ahead and notify the mentioned
      # users.
      mentioned_users.each do |u|
        un = UserNotification.create(:user_id => u.id, :notification_id => @post.id, :notification_type => "Post", :notified_at => Time.zone.now, :medium => UserNotification::Mediums::WEB)
      end

      render "api/v0/posts/show" and return
    else
      raise API::V0::Error.new(@post.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
  # DELETE /api/v0/posts/:id

  def destroy
    if @current_user.coordinator?
      @post = Post.find( params[:id] )
    else
      @post = @current_user.posts.find( params[:id] )
    end

    user = @post.user
    if @post.destroy
      points = user.total_points || 0
      user.update_column(:total_points, points - User::Points::POST_CREATED)
      user.teams.each do |team|
        team.update_column(:points, team.points - User::Points::POST_CREATED)
      end

      render :json => @post.as_json, :status => 200 and return
    else
      raise API::V0::Error.new(@post.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
end
