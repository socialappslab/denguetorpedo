# encoding: UTF-8

class PostsController < ApplicationController
  before_filter :require_login, :except => [:index]
  before_filter :load_wall, :except => [:like]

  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
    @post.user_id = @current_user.id
  end

  def create
    @wall.posts.create params[:post] do |post|
      post.user_id = @current_user.id
    end

    if params[:post][:content].empty?
      flash[:alert] = "Descreva a sua idéia."
    end

    redirect_to :back
  end

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
    post  = Post.find(params[:id])
    count = params[:count].to_i

    # Return immediately if the news instance can't be found or the user is
    # not logged in.
    render :nothing => true, :status => 400 if (post.blank? || @current_user.blank?)

    # If the user already liked the news, and has clicked like, then
    # remove their like. Otherwise, add a like.
    existing_like = post.likes.find {|like| like.user_id == @current_user.id }
    if existing_like
      existing_like.destroy
      count -= 1
    else
      Like.create(:user_id => @current_user.id, :likeable_id => post.id, :likeable_type => Post.name)
      count += 1
    end

    render :json => {'count' => count.to_s} and return
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def load_wall
    # TODO @dman7: This is not the way of identifying resources...
    resource, id = request.path.split('/')[3,4]
    @wall = resource.singularize.classify.constantize.find(id)
  end
end
