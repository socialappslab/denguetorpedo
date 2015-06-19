# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::LocationsController do
  let(:neighborhood)  { FactoryGirl.create(:neighborhood) }
  let(:breeding_site) { FactoryGirl.create(:breeding_site) }
  let(:user)          { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }

  describe "Requesting CSV only data" do
    render_views

    before(:each) do
      10.times do |index|
        FactoryGirl.create(:location, :address => "#{index}", :neighborhood_id => neighborhood.id)
      end

      l1 = Location.find_by_address("4")
      l2 = Location.find_by_address("5")

      FactoryGirl.create(:csv_report, :location_id => l1.id)
      FactoryGirl.create(:csv_report, :location_id => l2.id)
    end

    it "returns only the locations associated with CSVs" do
      get "index", :neighborhood_id => neighborhood.id, :csv_only => "1", :format => :json
      expect( JSON.parse(response.body)["locations"].map {|l| l["address"] } ).to eq(["4", "5"])
    end
  end
end
