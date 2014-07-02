# encoding: utf-8
require 'spec_helper'

describe TeamsController do
  let(:user) 						 { FactoryGirl.create(:user) }

  #-----------------------------------------------------------------------------

  before(:each) do
    cookies[:auth_token] = user.auth_token
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

  #---------------------------------------------------------------------------
end
