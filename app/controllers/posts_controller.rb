# encoding: UTF-8

class PostsController < ApplicationController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # POST /posts/

  def create
    @post                 = Post.new(params[:post])
    @post.user_id         = @current_user.id
    @post.neighborhood_id = @current_user.neighborhood_id

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

end
