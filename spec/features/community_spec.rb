# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Minha Comunidade", :type => :feature do
  let(:user) 	 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:sponsor) { FactoryGirl.create(:user, :role => User::Types::SPONSOR, :neighborhood_id => Neighborhood.first.id)}

  before(:each) do
    sign_in(user)
  end
end
