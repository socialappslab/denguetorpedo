# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::SessionsController do
  let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  describe "Successful authentication" do
    it "creates a new token" do
      post :create, :username => user.username, :password => user.password
      expect(JSON.parse(response.body)["token"]).not_to eq(nil)
    end
  end

  describe "Failed authentication" do
    it "returns proper error message" do
      post :create, :username => user.username, :password => "abc"
      expect(JSON.parse(response.body)["message"]).to eq("Invalid email or password. Please try again.")
    end
  end
end
