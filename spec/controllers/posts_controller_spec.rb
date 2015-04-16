require 'spec_helper'

describe PostsController do
  let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:team) { FactoryGirl.create(:team, :name => "Team", :neighborhood_id => Neighborhood.first.id) }
  let(:other_team) { FactoryGirl.create(:team, :name => "Other team", :neighborhood_id => Neighborhood.first.id) }

  #---------------------------------------------------------------------------

  before(:each) do
    request.env["HTTP_REFERER"] = root_path
    cookies[:auth_token]        = user.auth_token

    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => other_team.id, :user_id => user.id)
  end

  #---------------------------------------------------------------------------

  context "when creating a post" do
    it "awards points to the user" do
      before_points = user.total_points
      post "create", :post => {:title => "Hello", :content => "Testing"}
      expect(user.reload.total_points).to eq(before_points + User::Points::POST_CREATED)
    end

    it "sets the neighborhood to user's neighborhood" do
      before_points = user.total_points
      post "create", :post => {:title => "Hello", :content => "Testing"}

      p = Post.last
      expect(p.neighborhood_id).to eq(user.neighborhood_id)
    end

    it "awards points to the team" do
      before_points = team.points
      before_points_for_other_team = other_team.points
      post "create", :post => {:content => "Testing"}
      expect(team.reload.points).to eq(before_points + User::Points::POST_CREATED)
      expect(other_team.reload.points).to eq(before_points_for_other_team + User::Points::POST_CREATED)
    end

    it "associates a photo" do
      post "create", :post => {:title => "Hello", :content => "Testing", :compressed_photo => base64_image_string}
      p = Post.last
      expect(p.photo_file_size).not_to eq(nil)
    end
  end

  #---------------------------------------------------------------------------

end
