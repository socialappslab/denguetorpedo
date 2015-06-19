# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::GraphsController do
  let(:neighborhood)  { FactoryGirl.create(:neighborhood) }
  let(:breeding_site) { FactoryGirl.create(:breeding_site) }
  let(:user)          { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let(:location)       { FactoryGirl.create(:location, :address => "Test address", :neighborhood_id => neighborhood.id)}
  let!(:second_location)       { FactoryGirl.create(:location, :address => "New Test address", :neighborhood_id => neighborhood.id)}
  let!(:third_location)       { FactoryGirl.create(:location, :address => "New Test address again", :neighborhood_id => neighborhood.id)}
  let!(:fourth_location)       { FactoryGirl.create(:location, :address => "New Test address 3", :neighborhood_id => neighborhood.id)}
  let(:locations) { [location, second_location, third_location, fourth_location] }
  let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
  let!(:date2)    { DateTime.parse("2015-01-19 11:00") }
  let!(:date3)    { DateTime.parse("2015-01-28 11:00") }
  let!(:date4)    { DateTime.parse("2015-01-29 11:00") }


  before(:each) do
    cookies[:auth_token] = user.auth_token
    I18n.locale          = "es"

    # NOTE: Note the after_commit tag to trigger the hooks. This will create
    # the visits.
    # The distribution of houses is as follows:
    # First date had 2 visits to 2 (first and second) locations (first negative, second potential)
    # Second date had 1 visit to second location (second positive)
    # Third date had 2 visits to 2 (first and third) locations (first positive and third potential)
    # Fourth date had 1 visit to first location (first negative)
    FactoryGirl.create(:negative_report, :reporter_id => user.id, :location_id => location.id, :created_at => date1, :neighborhood_id => neighborhood.id)

    FactoryGirl.create(:potential_report, :reporter_id => user.id, :location_id => second_location.id, :created_at => date1, :neighborhood_id => neighborhood.id)

    FactoryGirl.create(:positive_report, :reporter_id => user.id, :location_id => second_location.id, :created_at => date2, :neighborhood_id => neighborhood.id)

    pos_report = FactoryGirl.create(:positive_report, :reporter_id => user.id, :location_id => location.id, :created_at => date3, :neighborhood_id => neighborhood.id)
    FactoryGirl.create(:potential_report, :reporter_id => user.id, :location_id => location.id, :created_at => date3, :neighborhood_id => neighborhood.id)

    FactoryGirl.create(:potential_report, :reporter_id => user.id, :location_id => third_location.id, :created_at => date3, :neighborhood_id => neighborhood.id)

    pos_report.completed_at  = date4
    pos_report.eliminated_at = date4
    pos_report.elimination_method_id = breeding_site.elimination_methods.first.id
    pos_report.save(:validate => false)

    Report.find_each do |r|
      r.update_column(:completed_at, date4)
    end
  end

  #---------------------------------------------------------------------------=

  describe "Request for charts", :after_commit => true do
    it "returns the correct time-series" do
      get :locations, "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1"
      visits = JSON.parse(response.body)
      expect(visits[1..-1]).to eq([
        ["2014-10-21", 0, 50, 50],
        ["2015-01-19", 100, 0, 0],
        ["2015-01-28", 50, 100, 0],
        ["2015-01-29", 0, 0, 100]
      ])
    end

    it "returns empty if time series contains no data since specified start time" do
      get :locations, :timeframe => "1", "percentages" => "daily", "positive" => "1","potential" => "1","negative" => "1"
      expect( JSON.parse(response.body).count ).to eq(1)
    end
  end


  #---------------------------------------------------------------------------=

  describe "Requesting CSV only data", :after_commit => true do
    render_views

    before(:each) do
      FactoryGirl.create(:csv_report, :location_id => second_location.id)
    end

    it "returns only the locations associated with CSVs" do
      get "locations", :neighborhood_id => neighborhood.id, "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1", :csv_only => "1", :format => :json
      expect( JSON.parse(response.body)[1..2] ).to eq( [["2014-10-21", 0, 100, 0], ["2015-01-19", 100, 0, 0]] )
    end
  end

end
