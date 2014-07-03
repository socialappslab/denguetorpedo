# encoding: UTF-8

class CommentssController < ApplicationController
  before_filter :require_login
  before_filter :identify_comment
  before_filter :ensure_valid_user

  #----------------------------------------------------------------------------

  def destroy
    if @comment.destroy
      render :json => {:success => true} and return
    else
      render :json => {:success => false} and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def identify_comment
    @comment = Comment.find(params[:id])
  end

  # This method verifies that the user fiddling with the comment is the one
  # who created it.
  def ensure_valid_user
    if @comment.user_id != @current_user.id
      render :json => { message: "You do not have permission to edit this comment" }, :status => 401
    end
  end

  #----------------------------------------------------------------------------

end
