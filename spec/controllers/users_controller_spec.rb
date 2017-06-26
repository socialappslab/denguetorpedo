# -*- encoding : utf-8 -*-
require "rails_helper"

describe UsersController do
  render_views

	before(:each) do
		I18n.locale = User::Locales::SPANISH
	end

  #-----------------------------------------------------------------------------

	context "Creating a user" do
    let(:org) { create(:organization) }

		it "requires organization id" do
			post :create
      expect(flash[:alert]).to eq("Debe seleccionar una organización")
		end

    it "creates a new user" do
      expect {
        post :create, "user"=>{"name"=>"Dmitri", "username"=>"abcdefg", "password"=>"abcdefg", "password_confirmation"=>"abcdefg", "neighborhood_id"=>"4"}, "organization_id" => org.id
      }.to change(User, :count).by(1)
		end

    it "sets to the active organization" do
      post :create, "user"=>{"name"=>"Dmitri", "username"=>"abcdefg", "password"=>"abcdefg", "password_confirmation"=>"abcdefg", "neighborhood_id"=>"4"}, "organization_id" => org.id
      expect(User.last.selected_membership.organization.id).to eq(org.id)
		end
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
