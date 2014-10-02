# encoding: UTF-8

class MessagesController < ApplicationController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # POST /users/:id/messages

  def create
    @conversations  = @current_user.conversations
    @conversation   = Conversation.new
    @message        = Message.new(params[:message])
    @users          = User.pluck(:username).to_json

    # Let's see if we need to create a new conversation depending on if the
    # conversation_id is not present. If not, then that means we're creating
    # a new conversation and message from the /conversations screen.
    if params[:message][:conversation_id].nil?
      # If the conversation is not present, then we're going to create one.
      # Before we do that, let's create the users in this conversation.
      # 1. Ensure that there are users addressed in the email.
      if params[:users].blank?
        flash[:show_new_message_form] = true
        flash[:alert] = I18n.t("views.conversations.flashes.errors.empty_recipients")
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

      unknown_users = users - known_users.map(&:username)
      if unknown_users.present?
        flash[:show_new_message_form] = true
        flash[:alert] =  I18n.t("views.conversations.flashes.errors.unknown_recipients", :recipients => unknown_users.join(', '))
        render "conversations/index" and return
      end

      # 3. At this point, we have users. Let's create the conversation and
      # the associations.
      @conversation = Conversation.create
      @conversation.users += known_users
      @conversation.users << @current_user if known_users.exclude?(@current_user)
      @conversation.save
    else
      @conversation = @current_user.conversations.find_by_id( params[:message][:conversation_id] )
    end

    # At this point, the conversation is identified, the users are known. Let's
    # create the message.
    @message.conversation_id = @conversation.id
    @message.body            = params[:message][:body]
    @message.user_id         = @current_user.id

    if @message.save
      # Let's touch the conversation to update that a new message has been
      # attached.
      @conversation.touch

      # Create a new notification for each user in the conversation, except
      # the creator.
      @conversation.users.each do |u|
        next if @current_user == u
        UserNotification.create(:user_id => u.id, :notification_type => UserNotification::Types::MESSAGE, :viewed => false)
      end

      flash[:notice] = I18n.t("views.conversations.flashes.success")
      redirect_to user_conversation_path(@current_user, @conversation) and return
    else
      flash[:show_new_message_form] = true
      flash[:alert] = I18n.t("views.conversations.flashes.errors.empty_body")
      redirect_to :back and return
    end
  end

  #----------------------------------------------------------------------------

end
