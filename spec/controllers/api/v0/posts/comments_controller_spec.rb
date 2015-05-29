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
  end

  #----------------------------------------------------------------------------

end
