# encoding: UTF-8

class PostsController < ApplicationController
  before_filter :require_login
  before_filter :find_by_id,   :only => [:like, :comment]

  #----------------------------------------------------------------------------
  # POST /posts/

  def create
    post         = Post.new(params[:post])
    post.user_id = @current_user.id

    if post.save
      @current_user.award_points_for_posting
      flash[:notice] = I18n.t("views.posts.success_create_flash")
      redirect_to :back and return
    else
      flash[:alert] = I18n.t("views.application.error")
      redirect_to :back and return
    end
  end

  #----------------------------------------------------------------------------
  # DELETE /posts/1

  def destroy
    post = Post.find( params[:id] )

    unless (post.user_id == @current_user.id || @current_user.coordinator?)
      flash[:alert] = I18n.t("views.application.permission_required")
      redirect_to root_path and return
    end

    if post.destroy
      points = @current_user.total_points || 0
      @current_user.update_column(:total_points, points - User::Points::POST_CREATED)
      @current_user.teams.each do |team|
        team.update_column(:points, team.points - User::Points::POST_CREATED)
      end

      flash[:notice] = I18n.t("activerecord.success.post.delete")
      redirect_to :back and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /posts/1/like

  def like
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
  # POST /posts/1/comment

  def comment
    redirect_to :back and return if ( @current_user.blank? || @post.blank? )

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @post.id, :commentable_type => Post.name)
    c.content = params[:comment][:content]
    if c.save
      Analytics.track( :user_id => @current_user.id, :event => "Commented on a post", :properties => {:post => @post.id}) if Rails.env.production?
      redirect_to :back, :notice => I18n.t("activerecord.success.comment.create") and return
    else
      redirect_to :back, :alert => I18n.t("attributes.content") + " " + I18n.t("activerecord.errors.comments.blank") and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def find_by_id
    @post = Post.find(params[:id])
  end

  #----------------------------------------------------------------------------

end
