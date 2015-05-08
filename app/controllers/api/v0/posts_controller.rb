# -*- encoding : utf-8 -*-
class API::V0::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user

  #----------------------------------------------------------------------------
  # GET /api/v0/posts

  def index
    # TODO: You're loading only your own posts!
    @posts = @current_user.posts.order("created_at DESC")

    user_hash = {
      :only    => [:id],
      :methods => [:display_name],
      :include => {
        :neighborhood => {
          :only => [],
          :methods => [:geographical_display_name]
        }
      }
    }

    # TODO: The comments are not ordered.
    posts_json = @posts.as_json(
      :only => [:id, :content, :likes_count],
      :include => [
        :user     => user_hash,
        :comments => {
          :only    => [:id, :content, :created_at],
          :methods => [:formatted_created_at],
          :include => { :user => user_hash }
        }
      ]
    )

    posts_json.each_with_index do |pjson, index|
      post = Post.find(pjson["id"])
      user = post.user
      next if pjson[:user].blank?

      if post.photo.present?
        pjson["image_path"] = post.photo.url(:large)
      end

      pjson["delete_path"] = api_v0_post_path(post)
      pjson["like_path"]   = like_api_v0_post_path(post)

      pjson["timestamp"] = view_context.timestamp_in_metadata(post.created_at)

      pjson[:user].merge!("image_path" => ActionController::Base.helpers.asset_path(user.picture) )
      pjson[:user].merge!("user_path"    => user_path(user))
      pjson[:user].merge!("neighborhood_path"    => neighborhood_path(user.neighborhood))

      if pjson[:comments].present?
        pjson[:comments].each do |cjson|
          comment = Comment.find(cjson["id"])
          cuser   = comment.user

          cjson["post_path"] = comment_post_path(comment)

          cjson["timestamp"] = view_context.timestamp_in_metadata(comment.created_at)
          cjson[:user].merge!("image_path" => ActionController::Base.helpers.asset_path(cuser.picture) )
          cjson[:user].merge!("user_path"    => user_path(cuser))
          cjson[:user].merge!("neighborhood_path"    => neighborhood_path(cuser.neighborhood))
        end
      end

    end

    render :json => {:posts => posts_json}, :status => 200 and return
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
  # POST api/v0/posts/:id/like

  def like
    @post = Post.find(params[:id])
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 if (@post.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @post.likes.find {|like| like.user_id == @current_user.id }
    if existing_like.present?
      existing_like.destroy
      count -= 1
      liekd  = false
    else
      Like.create(:user_id => @current_user.id, :likeable_id => @post.id, :likeable_type => Post.name)
      count += 1
      liked  = true

      Analytics.track( :user_id => @current_user.id, :event => "Liked a post", :properties => {:post => @post.id}) if Rails.env.production?
    end

    render :json => {'count' => count.to_s, "liked" => liked} and return
  end

  #----------------------------------------------------------------------------
end
