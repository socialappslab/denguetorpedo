# -*- encoding : utf-8 -*-

class PostsController < ApplicationController
  before_filter :require_login, :except => [:show]
  before_filter :find_by_id,   :only => [:like, :comment]

  #----------------------------------------------------------------------------
  # GET /posts/:id

  def show
    @post = Post.find(params[:id])

    @city = @post.user.city

    # Remove the specific notification from the array of @notifications!
    if @current_user
      notification = @notifications.where(:notification_type => "Post").where(:notification_id => @post.id).first
      notification.update_column(:seen_at, Time.zone.now) if notification.present?

      # NOTE: For now, we're clearing both comments and posts if they visit the post.
      # This may hold true for a long time.
      @notifications.where(:notification_type => "Comment").each do |n|
        n.update_column(:seen_at, Time.zone.now)
      end
    end
  end

  #----------------------------------------------------------------------------
  # POST /posts/

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
      @current_user.award_points_for_posting
      flash[:notice] = I18n.t("views.posts.success_create_flash")
      redirect_to :back and return
    else
      flash[:alert] = I18n.t("views.application.error")
      redirect_to :back and return
    end
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
