# -*- encoding : utf-8 -*-
require "rails_helper"

describe Coordinator::UsersController do
	let(:user)  { FactoryGirl.create(:user, :role => User::Types::COORDINATOR) }
  let(:user_params) { {:username => "abcdefg", :name => "Abc", :neighborhood_id => user.neighborhood.id, :password => "abcdefg", :password_confirmation => "abcdefg"} }

  before(:each) do
		I18n.locale = User::Locales::SPANISH
    cookies[:auth_token] = user.auth_token
	end

	it "allows to create a user" do
		expect {
			post :create, :user => user_params
		}.to change(User, :count).by(1)
	end
end
