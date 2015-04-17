class API::V0::PostsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :current_user
  before_filter :find_by_id,   :only => [:like, :comment]


  #----------------------------------------------------------------------------
  # POST api/v0/posts/1/like

  def like
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 if (@post.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = @post.likes.where(:user_id => @current_user.id).first
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
  # POST api/v0/posts/1/comment

  def comment
    render :nothing => true, :status => 400 if (@post.blank? || @current_user.blank?)

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @post.id, :commentable_type => Post.name)
    c.content = params[:comment][:content]
    if c.save
      Analytics.track( :user_id => @current_user.id, :event => "Commented on a post", :properties => {:post => @post.id}) if Rails.env.production?
      render :json => c.to_json(:methods => [:formatted_timestamp]) and return
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

  private

  def find_by_id
    @post = Post.find(params[:id])
  end

  #----------------------------------------------------------------------------

end
