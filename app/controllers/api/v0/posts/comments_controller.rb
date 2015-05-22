# -*- encoding : utf-8 -*-
class API::V0::Posts::CommentsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter      :current_user

  #----------------------------------------------------------------------------
  # POST /api/v0/posts/:post_id/comments
  #------------------------------------

  def create
    @post = Post.find(params[:post_id])

    # Create the comment.
    @comment = Comment.new
    @comment.content = params[:comment][:content]
    @comment.commentable_id = @post.id
    @comment.commentable_type = @post.class.name
    @comment.user_id = @current_user.id

    if @comment.save
      render "api/v0/comments/show" and return
    else
      raise API::V0::Error.new(@comment.errors.full_messages[0], 422)
    end
  end

  #----------------------------------------------------------------------------
end
