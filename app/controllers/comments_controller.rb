# encoding: UTF-8

class CommentsController < ApplicationController
  before_filter :require_login

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      render :json => {}, :status => 200
    else
      render :json => {}, :status => 404
    end
  end
end
