# encoding: UTF-8

class MessagesController < ApplicationController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # POST /users/:id/messages

  def create
    @conversations  = @current_user.conversations
    @conversation   = Conversation.new
    @message        = Message.new(params[:message])

    # Let's see if we need to create a new conversation depending on if the
    # conversation_id is not present. If not, then that means we're creating
    # a new conversation and message from the /conversations screen.
    if params[:message][:conversation_id].nil?
      # If the conversation is not present, then we're going to create one.
      # Before we do that, let's create the users in this conversation.
      # 1. Ensure that there are users addressed in the email.
      if params[:users].blank?
        flash[:show_new_message_form] = true
        flash[:alert] = "You need to include recipients for this message."
        render "conversations/index" and return
      end

      # 2. At this point, there are users. Identify users in the new message.
      # If at least one user can't be found, we abort and notify the creator.
      users         = params[:users].split(",").map {|u| u.strip}
      known_users   = []
      unknown_users = []
      users.each do |u|
        user = User.find_by_username( u )
        known_users << user if user.present?
      end

      puts "users: #{users}"
      puts "known_users: #{known_users.map(&:username)}"
      unknown_users = users - known_users.map(&:username)
      if unknown_users.present?
        flash[:show_new_message_form] = true
        flash[:alert] = "The message was not created because the following users could not be found: #{unknown_users.join(', ')}"
        render "conversations/index" and return
      end

      # 3. At this point, we have users. Let's create the conversation and
      # the associations.
      @conversation = Conversation.create
      @conversation.users += known_users
      @conversation.users << @current_user if known_users.exclude?(@current_user)
      @conversation.save
    else
      @conversation = Conversation.find_by_id(params[:message][:conversation_id])
    end

    # At this point, the conversation is identified, the users are known. Let's
    # create the message.
    @message.conversation_id = @conversation.id
    @message.body            = params[:message][:body]
    @message.user_id         = @current_user.id

    if @message.save
      flash[:notice] = "Message created successfully!"
      redirect_to user_conversation_path(@current_user, @conversation) and return
    else
      flash[:show_new_message_form] = true
      render "conversations/index" and return
    end
  end

  #----------------------------------------------------------------------------

end
