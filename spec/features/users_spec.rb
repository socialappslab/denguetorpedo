# encoding: utf-8

require 'spec_helper'
describe "Users", :type => :feature do
  context "when editing one's information" do
    let(:house) { FactoryGirl.create(:house) }
    let!(:user) { FactoryGirl.create(:user, :phone_number => nil, :carrier => nil, :house_id => house.id, :prepaid => nil, :neighborhood_id => Neighborhood.first.id) }

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

      it "keeps nickname information" do
        fill_in :user_nickname, :with => "I AM TESTER"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_nickname").value).to eq("I AM TESTER")
      end

      it "keeps nickname information" do
        selected_name = user.display_name_options[1]
        expect(find_field("user_display").value).not_to eq(selected_name[1])

        select selected_name[0], :from => "user_display"
        click_button I18n.t("views.buttons.update")
        expect(find_field("user_display").value).to eq(selected_name[1])
      end
    end
  end

  #---------------------------------------------------------------------------

end
