# encoding: UTF-8

class ConversationsController < ApplicationController
  before_filter :require_login

  def index
    @conversations  = @current_user.conversations
    @conversation   = Conversation.new
    @message        = Message.new
  end

  def show
    @conversation = @current_user.conversations.find_by_id(params[:id])
    @messages     = @conversation.messages.order("created_at ASC")
    @message      = Message.new
  end
end
