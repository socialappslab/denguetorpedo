# -*- encoding : utf-8 -*-

require 'spec_helper'
describe "Users", :type => :feature do
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
        find_field("user_carrier").value.should eq "xxx"
        find_field("user_phone_number").value.should eq "000000000000"
      end

      it "keeps gender information" do
        choose "user_gender_false"
        click_button I18n.t("views.buttons.update")
        expect(page).to have_css("#user_gender_false[checked='checked']")
      end

      it "keeps first name information" do
        fill_in :user_first_name, :with => "I AM TESTER"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_first_name").value).to eq("I AM TESTER")
      end


      it "keeps last name information" do
        fill_in :user_last_name, :with => "I AM TESTER"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_last_name").value).to eq("I AM TESTER")
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
