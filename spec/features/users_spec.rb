# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Users", :type => :feature do


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
        skip

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
        skip "Until we figure how to test jQuery Autocomplete"
        recruiter = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

        visit edit_user_path(user)
        select "MORADOR/VIZINHO", :from => "recruitment"

        fill_in "recruiter_name", with: recruiter.full_name
        click_button I18n.t("views.buttons.update")

      end
    end
  end

  #-----------------------------------------------------------------------------

  context "Logging a user in" do
    let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id, :email => "test@mailinator.com", :name => "Dmitri", :username => "dmitri") }

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

		it "allows login by email" do
			fill_in "username", :with => user.email
      fill_in "password", :with => user.password
      click_button "Entrar"

			expect(current_path).to eq(city_path(user.city))
		end

		it "allows login by username" do
			fill_in "username", :with => user.username
      fill_in "password", :with => user.password
      click_button "Entrar"

			expect(current_path).to eq(city_path(user.city))
		end

		it "allows login by name" do
			fill_in "username", :with => user.name
      fill_in "password", :with => user.password
      click_button "Entrar"

			expect(current_path).to eq(city_path(user.city))
		end
  end

  #-----------------------------------------------------------------------------

  context "Registering a user" do
    context "when user inputs valid information" do
      it "redirects them to the teams page" do
        visit root_path

				fill_in "user_name", 		 				:with => "test"
        fill_in "user_username", 		 				:with => "test"
        fill_in "user_password", 						 :with => "abcdefg"
        fill_in "user_password_confirmation", :with => "abcdefg"

        select("Ariel Darce, Managua", :from => "user_neighborhood_id")
        page.find(".submit-button").click

        expect(current_path).to eq( teams_path )
      end
    end

    it "displays errors" do
      FactoryGirl.create(:user, :username => "test", :neighborhood_id => Neighborhood.first.id)
      visit root_path

			fill_in "user_name", 		 			  		:with => "test"
      fill_in "user_username", 		 			  :with => "test"
      fill_in "user_password", 						 :with => "abcdefg"
      fill_in "user_password_confirmation", :with => "abcdefg"
      select(Neighborhood.first.name, :from => "user_neighborhood_id")
      page.find(".submit-button").click

      expect(page).to have_content( I18n.t("activerecord.errors.messages.taken") )
    end
  end

  #-----------------------------------------------------------------------------

  context "when editing one's information" do
    let!(:user)       { FactoryGirl.create(:user, :phone_number => nil, :carrier => nil, :prepaid => nil, :neighborhood_id => Neighborhood.first.id) }
    let(:coordinator) { FactoryGirl.create(:coordinator, :role => User::Types::COORDINATOR, :neighborhood_id => Neighborhood.first.id)}

    before(:each) do
      sign_in(user)
      visit edit_user_path(user)
    end

    context "when the form encounters an error" do
      it "keeps cellphone info" do
        # This is a hack that bypasses the need to have a JS driver.
        fill_in :user_phone_number, :with => "000000000000"
        fill_in :user_carrier, :with => "xxx"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_carrier").value).to eq "xxx"
        expect(find_field("user_phone_number").value).to eq "000000000000"
      end

      it "keeps gender information" do
        choose "user_gender_false"
        click_button I18n.t("views.buttons.update")
        expect(page).to have_css("#user_gender_false[checked='checked']")
      end

      it "keeps name information" do
        fill_in :user_name, :with => "I AM TESTER"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_name").value).to eq("I AM TESTER")
      end
    end

    context "when the coordinator edits a user" do
      before(:each) do
        sign_out(user)
        sign_in(coordinator)
        visit edit_user_path(user)
      end

      it "allows to change the password" do
        fill_in :user_password, :with => "testing"
        fill_in :user_password_confirmation, :with => "testing"
        click_button I18n.t("views.buttons.update")

        sign_out(coordinator)

        # Now, let's verify the password is indeed "testing"
        visit root_path
        fill_in "username", :with => user.username
        fill_in "password", :with => "testing"
        click_button "Entrar"
        expect(page).to have_content( I18n.t("activerecord.models.team", :count => 3) )
      end
    end
  end

  #---------------------------------------------------------------------------

end
