# -*- encoding : utf-8 -*-
require "rails_helper"

describe UsersController do
	before(:each) do
		I18n.locale = User::Locales::SPANISH
	end

	#-----------------------------------------------------------------------------

	context "Deleting a user" do
		let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id, :role => User::Types::COORDINATOR)  }
		let(:team) { FactoryGirl.create(:team, :name => "Team", :neighborhood_id => Neighborhood.first.id) }

		before(:each) do
			cookies[:auth_token] = user.auth_token
			FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
		end

		it "deletes the user from the database" do
			expect {
				delete :destroy, :id => user.id
			}.to change(User, :count).by(-1)
		end
	end

	#-----------------------------------------------------------------------------

end
