# encoding: utf-8
require 'spec_helper'

describe "Users", :type => :feature do

  #-----------------------------------------------------------------------------

  context "when editing one's information" do
    let!(:user) { FactoryGirl.create(:user, :phone_number => nil, :carrier => nil, :house_id => nil, :prepaid => nil, :neighborhood_id => nil, ) }

    before(:each) do
      sign_in(user)
      visit edit_user_path(user)
    end

    it "keeps house name in form on error" do
      fill_in :user_house_attributes_name, :with => "Test house"

      within ".edit_house" do
        click_button "Confirmar"
      end

      expect(page).to have_content("Informe a sua operadora")
      find_field("user_house_attributes_name").value.should eq "Test house"
    end

    it "keeps cellphone info in form on error" do
      check "cellphone"
      # This is a hack that bypasses the need to have a JS driver.
      fill_in :user_phone_number, :with => "000000000000"
      fill_in :user_carrier, :with => "xxx"

      within ".edit_house" do
        click_button "Confirmar"
      end

      expect(page).to have_content("Nome é obrigatório")
      find_field("user_carrier").value.should eq "xxx"
      find_field("user_phone_number").value.should eq "000000000000"
    end
  end

  #---------------------------------------------------------------------------

end
