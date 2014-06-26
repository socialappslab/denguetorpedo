# encoding: UTF-8

class PostsController < ApplicationController
  before_filter :require_login, :except => [:index]
  before_filter :load_wall, :except => [:like, :comment]
  before_filter :find_by_id, :only => [:like, :comment]

  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
    @post.user_id = @current_user.id
  end

  #----------------------------------------------------------------------------
  # POST /create ... and /neighborhood/1/houses/1/posts

  def create
    # TODO: Deprecate the @wall behavior...
    if @wall.nil?
      p = Post.new(params[:post])
      p.user_id = @current_user.id

      # TODO: Allow the specific errors to show through.
      if p.save
        flash[:notice] = I18n.t("views.posts.succes_create_flash")
        redirect_to :back and return
      else
        flash[:alert] = I18n.t("views.application.error")
        redirect_to :back and return
      end
    else
      @wall.posts.create params[:post] do |post|
        post.user_id = @current_user.id
      end
    end

    redirect_to :back and return
  end

  #----------------------------------------------------------------------------

  def show
    @post = Post.find params[:id]
    head :not_found and return if @post.nil?
  end

  def edit
    @post = Post.find params[:id]
    head :forbidden and return if @post.user_id != @current_user.id
  end

  def update
    post = Post.find params[:post][:id]
    head :not_found and return if post.nil?
    head :forbidden and return if post.user_id != @current_user.id
    post.update_attributes params[:post]
  end

  def destroy
    post = Post.find params[:id]
    head :forbidden and return if post.user_id != @current_user.id
    post.destroy
    redirect_to(:back)
  end

  #----------------------------------------------------------------------------
  # POST /users/1/posts/1/like

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
    end

    render :json => {'count' => count.to_s, "liked" => liked} and return
  end

  #----------------------------------------------------------------------------
  # POST /users/1/posts/1/comment

  def comment
    redirect_to :back and return if ( @current_user.blank? || @post.blank? )

    c         = Comment.new(:user_id => @current_user.id, :commentable_id => @post.id, :commentable_type => Post.name)
    c.content = params[:comment][:content]
    if c.save
      redirect_to :back, :notice => I18n.t("activerecord.success.comment.create") and return
    else
      redirect_to :back, :alert => I18n.t("attributes.content") + " " + I18n.t("activerecord.errors.comments.blank") and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def load_wall
    # TODO @dman7: This is not the way of identifying resources...
    resource, id = request.path.split('/')[3,4]

    return if resource.nil?
    @wall = resource.singularize.classify.constantize.find(id)
  end

  #----------------------------------------------------------------------------

  def find_by_id
    @post = Post.find(params[:id])
  end

  #----------------------------------------------------------------------------

end
