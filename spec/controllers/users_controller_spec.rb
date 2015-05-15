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

	context "Buying prizes" do
		let(:user)  { FactoryGirl.create(:user,  :neighborhood_id => Neighborhood.first.id, :total_points => 1000)  }
		let(:prize) { FactoryGirl.create(:prize, :user => user, :neighborhood_id => Neighborhood.first.id) }

		it "creates a PrizeCode instance" do
			expect {
				get :buy_prize, :id => user.id, :prize_id => prize.id
			}.to change(PrizeCode, :count).by(1)
		end

		it "updates user's total points" do
			before_point_count = user.total_points
			get :buy_prize, :id => user.id, :prize_id => prize.id
			expect(user.reload.total_points).to eq(before_point_count - prize.cost)
		end

		it "decreases prize stock" do
			before_count = prize.stock
			get :buy_prize, :id => user.id, :prize_id => prize.id
			expect(prize.reload.stock).to eq(before_count - 1)
		end
	end
end
