# encoding: utf-8
require 'spec_helper'

describe "Conversations", :type => :feature do
  let(:user)         { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.last.id) }
  let(:third_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:conversation) { FactoryGirl.create(:conversation) }

  before(:each) do
    sign_in(user)
    conversation.users += [user, other_user]
    conversation.save
  end

  context "when visiting /conversations" do
    it "displays existing conversations for each user involved" do
      visit user_conversations_path(user)
      expect(page).to have_content("Conversation between #{conversation.users.map(&:display_name).join(", ")}")
      expect(page).to have_content("Go to conversation")

      sign_out(user)
      sign_in(other_user)

      visit user_conversations_path(other_user)
      expect(page).to have_content("Conversation between #{conversation.users.map(&:display_name).join(", ")}")
      expect(page).to have_content("Go to conversation")
    end

    it "doesn't display conversations which users don't belong to" do
      sign_out(user)
      sign_in(third_user)

      visit user_conversations_path(third_user)
      expect(page).not_to have_content("Conversation between")
      expect(third_user.conversations.count).to eq(0)
    end
  end

  #---------------------------------------------------------------------------

  context "when creating a new message from existing conversations" do
    it "notifies if user forgot body" do
      visit user_conversation_path(user, conversation)
      click_button("Criar")
      expect(page).to have_content("Message body can't be empty.")
    end

    it "notifies the user of successful message" do
      visit user_conversation_path(user, conversation)
      fill_in "message[body]", :with => "Hello world!"
      click_button("Criar")
      expect(page).to have_content("Message created successfully!")
    end
  end

  #---------------------------------------------------------------------------

end
