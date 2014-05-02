# encoding: utf-8
require 'spec_helper'

describe "Minha Comunidade", :type => :feature do
  let(:user) 						{ FactoryGirl.create(:user) }

  before(:each) do
    sign_in(user)
  end

  it "renders the page" do
    visit neighborhood_path(user.neighborhood)
  end
end
