# -*- encoding : utf-8 -*-
require 'spec_helper'

describe API::V0::SessionsController do
  let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  describe "Successful authentication" do
    it "creates a new DeviceSession instance" do
      expect {
        post :create, :username => user.username, :password => user.password, :device => {:name => "Android"}
      }.to change(DeviceSession, :count).by(1)
    end

    it "creates a new token for the device" do
      post :create, :username => user.username, :password => user.password, :device => {:name => "Android"}
      expect(DeviceSession.last.token).not_to eq(nil)
    end

    it "associates the user to the new device session" do
      post :create, :username => user.username, :password => user.password, :device => {:name => "Android"}
      expect(DeviceSession.last.user_id).to eq(user.id)
    end
  end

  describe "Failed authentication" do
    it "avoids creating a new DeviceSession" do
      expect {
        post :create, :username => user.username, :password => "abc", :device => {:name => "Android"}
      }.not_to change(DeviceSession, :count).by(1)
    end
  end
end
