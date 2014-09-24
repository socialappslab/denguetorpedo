# encoding: UTF-8

class ConversationsController < ApplicationController
  before_filter :require_login

  def index
    @conversations = @current_user.conversations
  end

  def show
    @conversation = @current_user.conversations.find(:id => params[:id])
  end
end
