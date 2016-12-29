# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::VisitsController do
  render_views

  #--------------------------------------------------------------------------

  describe "Creating a visit" do
    let(:location) { create(:location) }
    let(:user)     { create(:user) }

    before(:each) do
      API::V0::BaseController.any_instance.stub(:authenticate_user_via_jwt).and_return(true)
      API::V0::BaseController.any_instance.stub(:current_user_via_jwt).and_return(user)
    end

    it "fails if location address can't be found" do
      post :create,  :visit => { :location_address => "TESTING" }
      expect(JSON.parse(response.body)["message"]).to eq("We couldn't find that location. Please try again.")
    end

    it "fails if date is not specified" do
      post :create,  :visit => { :location_address => location.address, :visited_at => "TEST"}
      expect(JSON.parse(response.body)["message"]).to eq("We couldn't parse the date. Please try again!")
    end

    it "creates a new visit with correct attributes" do
      post :create,  :visit => { :location_address => location.address, :visited_at => "2016-01-02"}
      v = Visit.last
      expect(v.visited_at.strftime("%Y-%m-%d")).to eq("2016-01-02")
      expect(v.location_id).to eq(location.id)
    end
  end
end
