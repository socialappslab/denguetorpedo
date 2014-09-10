# encoding: utf-8
require 'spec_helper'

describe "Landing Page", :type => :feature do
  let!(:user) 	 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  before(:each) do
    sign_in(user)
  end

  context "when choosing locale" do
    it "updates the user's locale to Spanish" do
      expect(user.locale).to eq(nil)
      visit "?locale=es"
      expect(user.reload.locale).to eq("es")
    end

    it "updates the user's locale to Portuguese" do
      expect(user.locale).to eq(nil)
      visit "?locale=pt"
      expect(user.reload.locale).to eq("pt")
    end
  end
end
