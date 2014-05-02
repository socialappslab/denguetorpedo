# encoding: utf-8
require 'spec_helper'

describe "Minha Comunidade", :type => :feature do
  let(:user) 	 { FactoryGirl.create(:user) }
  let(:sponsor) { FactoryGirl.create(:user, :role => User::Types::SPONSOR)}
  let!(:house)  { FactoryGirl.create(:house, :name => "Sponsor House", :neighborhood_id => sponsor.neighborhood.id, :house_type => sponsor.role) }

  before(:each) do
    sign_in(user)
  end

  it "doesn't display sponsor houses" do
    visit neighborhood_path(user.neighborhood)
    expect(page).not_to have_content("Sponsor House")
  end
end
