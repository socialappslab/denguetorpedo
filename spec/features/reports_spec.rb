require 'spec_helper'

describe "Reports" do
  describe "reports page" do
    context "when not looged in" do
      it "does not work" do
        # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
        visit reports_path
        page.status_code.should == 302
      end
    end

    context "when looged in" do
      before(:each) do
        @user = FactoryGirl.create(:user)
        visit root_path
        fill_in "E-mail", with: @user.email
        fill_in "Senha", with: "denguewarrior"
        click_button "Entrar"
      end
      it "works" do
        visit reports_path
        page.status_code.should == 200
      end
    end
  end

  describe "POST /reports" do
    context "with valid attributes" do
      it "should not work" do
        visit reports_path
      end
    end

    context "with invalid attributes" do
      it "should not work" do
        visit reports_path
      end
    end
  end
end
