# -*- encoding : utf-8 -*-
require "rails_helper"

describe SessionsController do
  let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  it "authenticates user when they login with username" do
    expect(cookies[:auth_token]).to eq(nil)
    post :create, :username => user.username, :password => user.password
    expect(cookies[:auth_token]).to eq(user.auth_token)
  end

  it "authenticates user when they login with email" do
    expect(cookies[:auth_token]).to eq(nil)
    post :create, :username => user.email, :password => user.password
    expect(cookies[:auth_token]).to eq(user.auth_token)
  end

  it "fails when user tries to authenticate with first name" do
    expect(cookies[:auth_token]).to eq(nil)
    post :create, :username => user.first_name, :password => user.password
    expect(cookies[:auth_token]).to eq(nil)
  end
end
