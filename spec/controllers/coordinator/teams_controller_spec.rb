# -*- encoding : utf-8 -*-
require "rails_helper"

describe Coordinator::TeamsController do
	let(:user)  { FactoryGirl.create(:user, :role => User::Types::COORDINATOR) }
  let(:user_params) { {:username => "abcdefg", :name => "Abc", :neighborhood_id => user.neighborhood.id, :password => "abcdefg", :password_confirmation => "abcdefg"} }

  before(:each) do
		I18n.locale = User::Locales::SPANISH
    cookies[:auth_token] = user.auth_token
	end

	#-----------------------------------------------------------------------------

	describe "Blocking teams" do
		let(:team) { FactoryGirl.create(:team, :name => "Test Team") }

		it "blocks a team" do
			get :block, :id => team.id
			expect(team.reload.blocked).to eq(true)
		end

		it "unblocks a blocked team" do
			team.update_attribute(:blocked, true)

			get :block, :id => team.id
			expect(team.reload.blocked).to eq(false)
		end
	end

	#-----------------------------------------------------------------------------

end
