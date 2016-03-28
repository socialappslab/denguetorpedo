# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::PostsController do
  let(:user)  { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id, :username => "dmitri") }
  let!(:blog_post) { FactoryGirl.create(:post, :content => "Test", :user_id => user.id)}
  let(:team)  { FactoryGirl.create(:team, :name => "Team", :neighborhood_id => Neighborhood.first.id) }
  let(:other_team) { FactoryGirl.create(:team, :name => "Other team", :neighborhood_id => Neighborhood.first.id) }

  describe "Loading posts in a city" do
    render_views
    let(:city)  { create(:city) }
    let(:user)  { FactoryGirl.create(:user) }

    #----------------------------------------------------------------------------

    describe "Loading posts" do
      let(:neighborhood) { create(:neighborhood, :city => city) }
      let!(:post) { create(:post, :user_id => user.id, :neighborhood_id => neighborhood.id) }

      before(:each) do
        cookies[:auth_token] = user.auth_token
      end

      it "successfully loads" do
        get :index, :city_id => city.id, :hashtag => "", :format => :json
        posts = JSON.parse(response.body)["posts"]
        expect(posts.count).to eq(1)
      end

      it "filters by hashtag" do
        get :index, :city_id => city.id, :hashtag => "testimonio", :format => :json
        posts = JSON.parse(response.body)["posts"]
        expect(posts).to eq([])
      end
    end
  end


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

    it "creates a UserNotification" do
      expect {
        post :create, :format => :json, :post => {:neighborhood_id => user.neighborhood_id, :content => "Hello world, @dmitri!"}
      }.to change(UserNotification, :count).by(1)
    end

    it "creates UserNotification with correct attributes" do
      post :create, :format => :json, :post => {:neighborhood_id => user.neighborhood_id, :content => "Hello world, @dmitri!"}
      un = UserNotification.last
      expect(un.user_id).to eq(user.id)
      expect(un.notification_id).to eq(Post.last.id)
      expect(un.notification_type).to eq("Post")
      expect(un.medium).to eq(UserNotification::Mediums::WEB)
      expect(un.notified_at.strftime("%Y-%M-%D")).to eq(Time.zone.now.strftime("%Y-%M-%D"))
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
    let(:other_user)  { create(:user) }
    let(:coordinator) { create(:coordinator) }

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
      expect(user.reload.total_points).to eq([0, before_points - User::Points::POST_CREATED].max)
    end

    it "remove points from team" do
      before_points = team.points
      before_points_for_other_team = other_team.points
      delete "destroy", :id => blog_post.id
      expect(team.reload.points).to eq(before_points - User::Points::POST_CREATED)
      expect(other_team.reload.points).to eq(before_points_for_other_team - User::Points::POST_CREATED)
    end

    it "doesn't allow normal users deleting other people's posts" do
      cookies[:auth_token] = other_user.auth_token
      expect {
        delete "destroy", :id => blog_post.id
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "allows coordinator to destroy a post" do
      cookies[:auth_token] = coordinator.auth_token
      expect {
        delete "destroy", :id => blog_post.id
      }.to change(Post, :count).by(-1)
    end
  end

  #----------------------------------------------------------------------------

end
