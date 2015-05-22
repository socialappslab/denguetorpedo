# -*- encoding : utf-8 -*-
class API::V0::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user

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

    if @post.save
      render "api/v0/posts/show" and return
    else
      raise API::V0::Error.new(@post.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
  # DELETE /api/v0/posts/:id

  def destroy
    @post = @current_user.posts.find( params[:id] )

    if @post.destroy
      points = @current_user.total_points || 0
      @current_user.update_column(:total_points, points - User::Points::POST_CREATED)
      @current_user.teams.each do |team|
        team.update_column(:points, team.points - User::Points::POST_CREATED)
      end

      render :json => @post.as_json, :status => 200 and return
    else
      raise API::V0::Error.new(@post.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
end
