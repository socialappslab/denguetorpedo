# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::CommentsController do
  let(:user)  { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:blog_post) { FactoryGirl.create(:post, :content => "Test", :user_id => user.id)}
  let!(:comment) { FactoryGirl.create(:comment, :user_id => user.id, :content => "Nice", :commentable_id => blog_post.id, :commentable_type => "Post")}
  let(:team) { FactoryGirl.create(:team, :name => "Team", :neighborhood_id => Neighborhood.first.id) }

  #----------------------------------------------------------------------------

  describe "Liking a comment" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
      FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    end

    it "increments likes_count" do
      post :like, :id => comment.id, :count => comment.likes_count
      expect(comment.reload.likes_count).to eq(1)
    end

    it "increments Like model" do
      expect {
        post :like, :id => comment.id, :count => comment.likes_count
      }.to change(Like, :count).by(1)
    end
  end

  #----------------------------------------------------------------------------

end
