# -*- encoding : utf-8 -*-
require 'spec_helper'

describe UsersController do
	render_views

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

	context "Registering a user" do
		context "when user inputs valid information" do
			it "redirects them to their edit page" do
				visit root_path

				fill_in "user_username", 		 				:with => "test"
				fill_in "user_password", 						 :with => "abcdefg"
				fill_in "user_password_confirmation", :with => "abcdefg"

				n = Neighborhood.last
				select("#{n.name}, #{n.city.name}", :from => "user_neighborhood_id")
				page.find(".submit-button").click

				expect(current_path).to eq( teams_path )
			end
		end

		it "allows them to fully register seamlessly" do
			visit root_path

			fill_in "user_username", 		 			  :with => "test"
			fill_in "user_password", 						 :with => "abcdefg"
			fill_in "user_password_confirmation", :with => "abcdefg"
			select(Neighborhood.last.name, :from => "user_neighborhood_id")
			page.find(".submit-button").click

			expect(page).to have_content( I18n.t("views.users.create_success_flash") )
		end

		it "notifies them of existing username" do
			FactoryGirl.create(:user, :username => "test", :neighborhood_id => Neighborhood.first.id)
			visit root_path

			fill_in "user_username", 		 			  :with => "test"
			fill_in "user_password", 						 :with => "abcdefg"
			fill_in "user_password_confirmation", :with => "abcdefg"
			select(Neighborhood.last.name, :from => "user_neighborhood_id")
			page.find(".submit-button").click

			expect(page).to have_content( I18n.t("activerecord.errors.messages.taken") )
		end
	end

	#-----------------------------------------------------------------------------

	context "Logging a user in" do
		let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

		before(:each) do
			visit root_path
		end

		it "displays appropriate error message for invalid input" do
			fill_in "username", :with => user.username
			fill_in "password", :with => ""
			click_button "Entrar"

			expect(page).to have_content( I18n.t("views.flashes.login.error") )
			expect(page).not_to have_content("Invalid email")
		end

		it "doesn't display Signed in message" do
			fill_in "username", :with => user.username
			fill_in "password", :with => user.password
			click_button "Entrar"

			expect(page).not_to have_content("Signed in")
		end
	end

	#-----------------------------------------------------------------------------

	context "Logging a user out" do
		let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

		before(:each) do
			sign_in(user)
		end

		it "doesn't display Signed out message" do
			visit logout_path

			expect(page).not_to have_content("Signed out")
		end
	end

	#-----------------------------------------------------------------------------

	context "Editing a user" do
		let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

		before(:each) do
			sign_in(user)
		end

		context "when user inputs valid information" do
			it "updates the user's neighborhood" do
				# TODO: Pending until we introduce a second neighborhood
				pending

				expect(user.neighborhood_id).to eq(Neighborhood.first.id)

				visit edit_user_path(user)

				select Neighborhood.all[1].id, :from =>  "user_neighborhood_id"
				click_button I18n.t("views.buttons.update")
				expect(user.reload.neighborhood_id).to eq(Neighborhood.all[1].id)
				expect(page).to have_content("Perfil atualizado com sucesso")
			end

			it "updates user's phone number and carrier" do
				visit edit_user_path(user)

				fill_in :user_phone_number, :with => "123456789101"
				fill_in :user_carrier, :with => "test"
				click_button I18n.t("views.buttons.update")
				expect(user.reload.phone_number).to eq("123456789101")
				expect(user.reload.carrier).to eq("test")
			end
		end

		context "when editing recruiter information" do
			it "updates the recruiter id when user selects a recruiter" do
				pending "Until we figure how to test jQuery Autocomplete"
				recruiter = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

				visit edit_user_path(user)
				select "MORADOR/VIZINHO", :from => "recruitment"

				fill_in "recruiter_name", with: recruiter.full_name
				click_button I18n.t("views.buttons.update")

			end
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
