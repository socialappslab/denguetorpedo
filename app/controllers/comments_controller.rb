# encoding: UTF-8

class CommentsController < ApplicationController
  before_filter :require_login

  def destroy
    @comment = Comment.find(params[:id])

    respond_to do |format|
      if @comment.destroy
        format.json { render :json => {}, :status => 200 }
      else
        format.json { render :json => {}, :status => 404 }
      end

      format.html{ redirect_to :back and return }
    end

  end
end
