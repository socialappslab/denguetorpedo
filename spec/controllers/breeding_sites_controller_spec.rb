require 'spec_helper'

describe BreedingSitesController do
  let(:user)              { FactoryGirl.create(:user, :role => User::Types::COORDINATOR, :neighborhood_id => Neighborhood.first.id) }
  let(:unauthorized_user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

  before(:each) do
    cookies[:auth_token] = user.auth_token
  end

  #----------------------------------------------------------------------------

  context "when accessing as a regular user" do
    before(:each) do
      cookies[:auth_token] = unauthorized_user.auth_token
    end

    it "redirect to home" do
      expect(
        post "create", :breeding_site => { :description_in_es => "Test" }
      ).to redirect_to(root_path)
    end
  end

  #----------------------------------------------------------------------------

end
