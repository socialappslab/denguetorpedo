# -*- encoding : utf-8 -*-
require "rails_helper"

describe TeamsController do
  let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:team) { FactoryGirl.create(:team, :name => "Test", :neighborhood_id => Neighborhood.first.id) }
  let(:coordinator) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id) }

  #-----------------------------------------------------------------------------

  before(:each) do
    cookies[:auth_token] = user.auth_token
    request.env["HTTP_REFERER"] = administer_teams_path
  end

  it "fails to create a team with no name" do
    expect {
      post :create, :team => {}
    }.not_to change(Team, :count)
  end

  it "creates a TeamMembership for a new team" do
    expect {
      post :create, :team => {:name => "test"}
    }.to change(TeamMembership, :count).by(1)
  end

  it "assigns correct neighborhood" do
    tepalcingo = Neighborhood.find_by_name("Tepalcingo")
    user.update_attribute(:neighborhood_id, tepalcingo.id)
    user.reload

    post :create, :team => {:name => "test"}

    t = Team.last
    expect(t.neighborhood_id).to eq(tepalcingo.id)
  end

  #---------------------------------------------------------------------------
end
