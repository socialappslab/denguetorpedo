# -*- encoding : utf-8 -*-

class ConversationsController < ApplicationController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /users/:user_id/conversations
  #----------------------------------

  def index
    @conversations  = @current_user.conversations.order("updated_at DESC")
    @conversation   = Conversation.new
    @message        = Message.new
    @users          = User.pluck(:username).to_json

    @notifications.where(:notification_type => "Message").each do |mn|
      mn.update_column(:seen_at, Time.zone.now)
    end

    @notifications = []
  end

  #----------------------------------------------------------------------------
  # GET /users/:user_id
  #----------------------------------

  def show
    @conversation = @current_user.conversations.find_by_id(params[:id])
    @messages     = @conversation.messages.order("created_at ASC")
    @message      = Message.new
  end

  #----------------------------------------------------------------------------
end
