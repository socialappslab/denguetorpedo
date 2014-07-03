# encoding: UTF-8

class CommentsController < ApplicationController
  before_filter :require_login

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      flash[:notice] = I18n.t("views.comments.success_delete_flash")
      redirect_to :back
    else
      flash[:alert] = I18n.t("views.application.error")
      redirect_to :back
    end
  end
end
