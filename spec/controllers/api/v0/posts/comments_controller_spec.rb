# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::Posts::CommentsController do
  let(:user)       { FactoryGirl.create(:user, :username => "dmitri") }
  let!(:blog_post) { FactoryGirl.create(:post, :content => "Test", :user_id => user.id)}

  #----------------------------------------------------------------------------

  describe "Creating a comment" do
    render_views

    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "wraps mentions in <a> tag" do
      post :create, :format => :json, :post_id => blog_post.id, :comment => {:content => "Hello world, @dmitri!"}
      expect(Comment.last.content).to include("<a href='#{user_path(user)}'>@#{user.username}</a>")
    end

    it "leaves unidentified user mentions as is" do
      post :create, :format => :json, :post_id => blog_post.id, :comment => {:content => "Hello world, @hahaha!"}
      expect(Comment.last.content).not_to include("<a href='#{user_path(user)}'>@#{user.username}</a>")
    end

    it "creates a UserNotification" do
      expect {
        post :create, :format => :json, :post_id => blog_post.id, :comment => {:content => "Hello world, @dmitri!"}
      }.to change(UserNotification, :count).by(1)
    end

    it "creates UserNotification with correct attributes" do
      post :create, :format => :json, :post_id => blog_post.id, :comment => {:content => "Hello world, @dmitri!"}
      un = UserNotification.last
      expect(un.user_id).to eq(user.id)
      expect(un.notification_id).to eq(Comment.last.id)
      expect(un.notification_type).to eq("Comment")
      expect(un.medium).to eq(UserNotification::Mediums::WEB)
      expect(un.notified_at.strftime("%Y-%M-%D")).to eq(Time.zone.now.strftime("%Y-%M-%D"))
    end
  end

  #----------------------------------------------------------------------------

end
