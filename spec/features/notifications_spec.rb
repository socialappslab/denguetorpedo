# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Notifications", :type => :feature do
  let!(:user) 	 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:team) 	 { FactoryGirl.create(:team, :name => "Test") }

  before(:each) do
    team.users << user
    sign_in(user)
  end

  #----------------------------------------------------------------------------

  describe "Post" do
    before(:each) do
      @post = FactoryGirl.create(:post, :content => "Test", :user_id => user.id)
      FactoryGirl.create(:post_notification, :user_id => user.id, :notification_id => @post.id)
      visit "/"
    end
    it "displays icon" do
      expect(page).to have_css(".label")
    end

    it "displays proper message", :js => true do
      page.find(".dropdown a").click
      expect(page).to have_content("Alguien te mencionado en un chat!")
    end

    it "redirects to proper URL", :js => true do
      page.find(".dropdown a").click
      page.find(".dropdown-menu a").click
      expect(current_path).to eq(post_path(@post))
    end

    context "with many notifications" do
      before(:each) do
        c = FactoryGirl.create(:comment, :content => "Test", :commentable_id => @post.id, :commentable_type => "Post", :user_id => user.id)

        FactoryGirl.create(:comment_notification, :user_id => user.id, :notification_id => c.id)
        FactoryGirl.create(:message_notification, :user_id => user.id, :notification_id => 1)

        visit post_path(@post)
      end

      it "clears all Post notifications but keeps Message notifications" do
        expect(user.new_notifications.reload.where(:notification_type => "Post").count).to eq(0)
        expect(user.new_notifications.where("notification_type != 'Post'").count).to eq(1)
      end
    end
  end

  #----------------------------------------------------------------------------

  describe "Comment" do
    before(:each) do
      @post = FactoryGirl.create(:post, :content => "Test", :user_id => user.id)
      c = FactoryGirl.create(:comment, :content => "Test", :commentable_id => @post.id, :commentable_type => "Post", :user_id => user.id)
      FactoryGirl.create(:comment_notification, :user_id => user.id, :notification_id => c.id)

      visit "/"
    end

    it "displays icon" do
      expect(page).to have_css(".label")
    end

    it "displays proper message", :js => true do
      page.find(".label-danger").click
      expect(page).to have_content("Alguien te mencionado en un comentario!")
    end

    it "redirects to proper URL", :js => true do
      page.find(".dropdown a").click
      page.find(".dropdown-menu a").click
      expect(current_path).to eq(post_path(@post))
    end

    context "with many notifications" do
      before(:each) do
        FactoryGirl.create(:message_notification, :user_id => user.id, :notification_id => 1)
        visit post_path(@post)
      end

      it "clears all Post/Comment notifications but keeps Message notifications" do
        expect(user.new_notifications.where(:notification_type => "Comment").count).to eq(0)
        expect(user.new_notifications.where("notification_type != 'Comment'").count).to eq(1)
      end
    end

  end

end
