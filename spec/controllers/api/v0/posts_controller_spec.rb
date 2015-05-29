# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::PostsController do
  let(:user)  { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id, :username => "dmitri") }
  let!(:blog_post) { FactoryGirl.create(:post, :content => "Test", :user_id => user.id)}
  let(:team)  { FactoryGirl.create(:team, :name => "Team", :neighborhood_id => Neighborhood.first.id) }
  let(:other_team) { FactoryGirl.create(:team, :name => "Other team", :neighborhood_id => Neighborhood.first.id) }

  #----------------------------------------------------------------------------

  describe "Creating a post" do
    render_views
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "wraps mentions in <a> tag" do
      post :create, :format => :json, :post => {:neighborhood_id => user.neighborhood_id, :content => "Hello world, @dmitri!"}
      expect(Post.last.content).to include("<a href='#{user_path(user)}'>@#{user.username}</a>")
    end

    it "leaves unidentified user mentions as is" do
      post :create, :format => :json, :post => {:neighborhood_id => user.neighborhood_id, :content => "Hello world, @hahaha!"}
      expect(Post.last.content).not_to include("<a href='#{user_path(user)}'>@#{user.username}</a>")
    end
  end

  #----------------------------------------------------------------------------

  describe "Liking a post" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "changes likes_count" do
      post :like, :id => blog_post.id, :count => blog_post.likes_count
      expect(blog_post.reload.likes_count).to eq(1)
    end

    it "increments Like model" do
      expect {
        post :like, :id => blog_post.id, :count => blog_post.likes_count
      }.to change(Like, :count).by(1)
    end
  end

  #----------------------------------------------------------------------------

  describe "Deleting a post" do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
      FactoryGirl.create(:team_membership, :team_id => other_team.id, :user_id => user.id)
    end

    it "decrements Post count" do
      expect {
        delete :destroy, :id => blog_post.id
      }.to change(Post, :count).by(-1)
    end

    it "remove points from the user" do
      before_points = user.total_points
      delete "destroy", :id => blog_post.id
      expect(user.reload.total_points).to eq(before_points - User::Points::POST_CREATED)
    end

    it "remove points from team" do
      before_points = team.points
      before_points_for_other_team = other_team.points
      delete "destroy", :id => blog_post.id
      expect(team.reload.points).to eq(before_points - User::Points::POST_CREATED)
      expect(other_team.reload.points).to eq(before_points_for_other_team - User::Points::POST_CREATED)
    end
  end

  #----------------------------------------------------------------------------

end
