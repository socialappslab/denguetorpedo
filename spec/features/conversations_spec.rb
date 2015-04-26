# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Conversations", :type => :feature do
  let(:team)         { FactoryGirl.create(:team, :neighborhood_id => Neighborhood.first.id, :name => "Test Team") }
  let(:user)         { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.last.id)  }
  let(:third_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:conversation) { FactoryGirl.create(:conversation) }

  before(:each) do
    sign_in(user)
    conversation.users += [user, other_user]
    conversation.save
    FactoryGirl.create(:team_membership, :user_id => user.id, :team_id => team.id)
  end

  context "when visiting /conversations" do
    it "clears all notifications" do
      un = FactoryGirl.create(:user_notification, :user_id => user.id, :notification_type => UserNotification::Types::MESSAGE)
      visit user_conversations_path(user)
      expect(page).not_to have_css(".badge")
    end

    it "displays existing conversations for each user involved" do
      visit user_conversations_path(user)
      expect(page).to have_content(I18n.t("views.conversations.index.messages_between") + " #{conversation.users.map(&:display_name).join(", ")}")
      expect(page).to have_content( I18n.t("views.conversations.index.visit_messages") )

      sign_out(user)
      sign_in(other_user)

      visit user_conversations_path(other_user)
      expect(page).to have_content(I18n.t("views.conversations.index.messages_between")+ " #{conversation.users.map(&:display_name).join(", ")}")
      expect(page).to have_content( I18n.t("views.conversations.index.visit_messages") )
    end

    it "doesn't display conversations which users don't belong to" do
      sign_out(user)
      sign_in(third_user)

      visit user_conversations_path(third_user)
      expect(page).not_to have_content( I18n.t("views.conversations.index.messages_between") )
      expect(third_user.conversations.count).to eq(0)
    end

    # NOTE: This requires us to install a JS driver.
    # it "renders conversation/show if user forgets body" do
    #   visit user_conversations_path(user)
    #   save_and_open_page
    #   fill_in "users", :with => other_user.username
    #   click_button("Criar")
    #   c = Conversation.last
    #   expect(current_path).to eq( user_conversation_path(user, c) )
    # end
  end

  #---------------------------------------------------------------------------

  context "when creating a new message from existing conversations" do
    it "notifies if user forgot body" do
      visit user_conversation_path(user, conversation)
      click_button("Enviar")
      expect(page).to have_content( "es obligatorio" )
    end

    it "notifies the user of successful message" do
      visit user_conversation_path(user, conversation)
      fill_in "message[body]", :with => "Hello world!"
      click_button("Enviar")
      expect(page).to have_content( I18n.t("views.conversations.flashes.success") )
    end
  end

  #---------------------------------------------------------------------------

end
