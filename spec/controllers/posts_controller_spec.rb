# -*- encoding : utf-8 -*-
require "rails_helper"

describe PostsController do
  let(:n)           { FactoryGirl.create(:neighborhood) }
  let(:user)       { FactoryGirl.create(:user) }
  let(:team)       { FactoryGirl.create(:team, :name => "Team") }
  let(:other_team) { FactoryGirl.create(:team, :name => "Other team") }

  #---------------------------------------------------------------------------

  before(:each) do
    request.env["HTTP_REFERER"] = root_path
    cookies[:auth_token]        = user.auth_token

    team.users       << user
    other_team.users << user
  end

  #---------------------------------------------------------------------------

  context "when creating a post" do
    it "awards points to the user" do
      before_points = user.total_points
      post "create", :post => {:title => "Hello", :content => "Testing", :neighborhood_id => n.id}
      expect(user.reload.total_points).to eq(before_points + User::Points::POST_CREATED)
    end

    it "assigns the neighborhood" do
      before_points = user.total_points
      post "create", :post => {:title => "Hello", :content => "Testing", :neighborhood_id => n.id}
      expect(Post.last.neighborhood_id).to eq(n.id)
    end

    it "awards points to the team" do
      before_points = team.points
      before_points_for_other_team = other_team.points
      post "create", :post => {:content => "Testing", :neighborhood_id => n.id}
      expect(team.reload.points).to eq(before_points + User::Points::POST_CREATED)
      expect(other_team.reload.points).to eq(before_points_for_other_team + User::Points::POST_CREATED)
    end

    it "associates a photo" do
      post "create", :post => {:title => "Hello", :content => "Testing", :neighborhood_id => n.id, :compressed_photo => base64_image_string}
      p = Post.last
      expect(p.photo_file_size).not_to eq(nil)
    end
  end

  #---------------------------------------------------------------------------

end
