# encoding: utf-8
require 'spec_helper'

describe "Landing Page", :type => :feature do
  let!(:user) 	 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  context "when visiting logged-in" do
    before(:each) do
      sign_in(user)
    end

    it "displays notifications if user has any" do
      FactoryGirl.create(:user_notification, :user_id => user.id, :notification_type => UserNotification::Types::MESSAGE)
      visit "/"
      expect(page).to have_css(".badge")
    end
  end
end
