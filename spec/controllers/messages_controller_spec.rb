# -*- encoding : utf-8 -*-
require "rails_helper"

describe MessagesController do
  let(:user)         { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:conversation) { FactoryGirl.create(:conversation) }

  before(:each) do
    cookies[:auth_token] = user.auth_token
  end

  describe "Creating a new message from index view" do
    before(:each) do
      request.env["HTTP_REFERER"] = user_conversations_path(user)
    end

    context "with errors" do
      describe "a Message instance is not created" do
        it "if no users are specified" do
          expect {
            post "create", :message => {:body => "Hello"}
          }.not_to change(Message, :count)
        end

        it "if some users are not found" do
          expect {
            post "create", :message => {:body => "Hello"}, :users => "#{user.username}, test@mailinator.com"
          }.not_to change(Message, :count)
        end

        it "if body is missing" do
          expect {
            post "create", :users => "#{user.username}", :message => {}
          }.not_to change(Message, :count)
        end
      end

      describe "a Conversation instance is not created" do
        it "if no users are specified" do
          expect {
            post "create", :message => {:body => "Hello"}
          }.not_to change(Conversation, :count)
        end

        it "if some users are not found" do
          expect {
            post "create", :message => {:body => "Hello"}, :users => "#{user.username}, test@mailinator.com"
          }.not_to change(Conversation, :count)
        end
      end

      describe "a UserNotification instance is not created" do
        it "if no users are specified" do
          expect {
            post "create", :message => {:body => "Hello"}
          }.not_to change(UserNotification, :count)
        end

        it "if some users are not found" do
          expect {
            post "create", :message => {:body => "Hello"}, :users => "#{user.username}, test@mailinator.com"
          }.not_to change(UserNotification, :count)
        end
      end
    end

    #--------------------------------------------------------------------------

    context "with success" do
      let(:params) { { :users => "#{user.username}, #{other_user.username}", :message => {:body => "Hello"} } }

      it "creates a new message" do
        expect {
          post "create", params
        }.to change(Message, :count).by(1)
      end

      it "creates a new notification only for non-current user" do
        expect {
          post "create", params
        }.to change(UserNotification, :count).by(1)
      end

      it "creates a new notification with correct attributes" do
        post "create", params
        n = UserNotification.last
        expect(n.user_id).to eq(other_user.id)
        expect(n.notification_type).to eq("Message")
        expect(n.seen_at).to eq(nil)
      end

      it "creates a message with correct attributes" do
        post "create", params
        m = Message.last
        c = Conversation.last
        expect(m.body).to eq("Hello")
        expect(m.user_id).to eq(user.id)
        expect(m.conversation_id).to eq(c.id)
      end

      it "creates a new conversation" do
        expect {
          post "create", params
        }.to change(Conversation, :count).by(1)
      end

      it "creates a conversation with correct attributes" do
        post "create", params
        c = Conversation.last
        expect(c.users).to eq( [user, other_user] )
      end
    end
  end

  #--------------------------------------------------------------------------

  describe "Creating a message from conversations view" do
    before(:each) do
      request.env["HTTP_REFERER"] = user_conversation_path(user, conversation)

      conversation.users += [user, other_user]
      conversation.save
    end

    let(:params) { { :users => "#{user.username}, #{other_user.username}", :message => {:body => "Hello", :conversation_id => conversation.id} } }
    it "does not create a conversation" do
      expect {
        post "create", params
      }.not_to change(Conversation, :count)
    end
  end


end
