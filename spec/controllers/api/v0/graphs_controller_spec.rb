# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::GraphsController do
  let(:neighborhood)  { create(:neighborhood) }
  let(:user)          { create(:user) }
  let(:loc)           { create(:location, :address => "Test address", :neighborhood_id => neighborhood.id)}
  let!(:loc2)         { create(:location, :address => "New Test address", :neighborhood_id => neighborhood.id)}
  let!(:loc3)         { create(:location, :address => "New Test address again", :neighborhood_id => neighborhood.id)}
  let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
  let!(:date2)    { DateTime.parse("2015-01-19 11:00") }
  let!(:date3)    { DateTime.parse("2015-01-28 11:00") }
  let!(:date4)    { DateTime.parse("2015-01-29 11:00") }


  before(:each) do
    cookies[:auth_token] = user.auth_token
    I18n.locale          = "es"

    [
      [:negative_report, loc, date1],
      [:potential_report, loc2, date1],
      [:positive_report, loc2, date2],
      [:positive_report, loc, date3],
      [:potential_report, loc, date3],
      [:potential_report, loc3, date3],
    ].each do |h|
      type_of_report = h[0]
      location       = h[1]
      date           = h[2]

      r = build_stubbed(type_of_report, :location_id => location.id, :created_at => date, :neighborhood => neighborhood)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
    end

    pos_report = build_stubbed(:positive_report, :location_id => loc.id, :created_at => date3)
    pos_report.completed_at  = date4
    pos_report.eliminated_at = date4
    pos_report.elimination_method_id = 1
    v = pos_report.find_or_create_visit_for_date(date4)
    pos_report.update_inspection_for_visit(v)
  end

  #---------------------------------------------------------------------------=

  describe "#locations" do
    it "returns the correct time-series" do
      get :locations, :neighborhood_id => neighborhood.id,  "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1"
      visits = JSON.parse(response.body)

      [1, 2, 3, 4].each do |index|
        visits["data"][index]["positive"].delete("locations")
        visits["data"][index]["potential"].delete("locations")
        visits["data"][index]["negative"].delete("locations")
      end

      expect(visits["data"]).to eq(
        [
          ["Tiempo", "Lugares con criaderos positivos", "Lugares con criaderos potenciales","Lugares sin criaderos"],
          {"date"=>"2014-10-21", "positive"=>{"count"=>0, "percent"=>0}, "potential"=>{"count"=>1, "percent"=>50}, "negative"=>{"count"=>1, "percent"=>50}, "total"=>{"count"=>2}},
          {"date"=>"2015-01-19", "positive"=>{"count"=>1, "percent"=>100}, "potential"=>{"count"=>0, "percent"=>0}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>1}},
          {"date"=>"2015-01-28", "positive"=>{"count"=>1, "percent"=>50}, "potential"=>{"count"=>2, "percent"=>100}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>2}},
          {"date"=>"2015-01-29", "positive"=>{"count"=>0, "percent"=>0}, "potential"=>{"count"=>0, "percent"=>0}, "negative"=>{"count"=>1, "percent"=>100}, "total"=>{"count"=>1}}
        ]
      )
    end

    it "returns the correct loc ids" do
      get :locations, :neighborhood_id => neighborhood.id,  "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1"
      visits = JSON.parse(response.body)["data"]

      expect(visits[1]["positive"]["locations"]).to eq([])
      expect(visits[1]["potential"]["locations"]).to eq([loc2.id])
      expect(visits[1]["negative"]["locations"]).to eq([loc.id])

      expect(visits[2]["positive"]["locations"]).to eq([loc2.id])
      expect(visits[2]["potential"]["locations"]).to eq([])
      expect(visits[2]["negative"]["locations"]).to eq([])


      expect(visits[3]["positive"]["locations"]).to eq([loc.id])
      expect(visits[3]["potential"]["locations"]).to eq([loc.id, loc3.id])
      expect(visits[3]["negative"]["locations"]).to eq([])


      expect(visits[4]["positive"]["locations"]).to eq([])
      expect(visits[4]["potential"]["locations"]).to eq([])
      expect(visits[4]["negative"]["locations"]).to eq([loc.id])
    end

    it "returns empty if time series contains no data since specified start time" do
      get :locations, :neighborhood_id => neighborhood.id, :timeframe => "1", "percentages" => "daily", "positive" => "1","potential" => "1","negative" => "1"
      expect( JSON.parse(response.body)["data"].count ).to eq(1)
    end

    it "returns an array of locs" do
      get :locations, :neighborhood_id => neighborhood.id, "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1"
      visits = JSON.parse(response.body)
      expect(visits["locations"].map {|l| l["id"] }.sort ).to eq(Location.pluck(:id).sort)
    end

    it "returns only the locs associated with CSVs" do
      create(:csv_report, :location_id => loc2.id)

      get :locations, :neighborhood_id => neighborhood.id, "percentages" => "daily", "positive" => "1", "potential" => "1", "negative" => "1", :csv_only => "1", :format => :json

      visits = JSON.parse(response.body)["data"]
      [1, 2].each do |index|
        visits[index]["positive"].delete("locations")
        visits[index]["potential"].delete("locations")
        visits[index]["negative"].delete("locations")
      end

      expect( visits[1..2] ).to eq( [
        {"date"=>"2014-10-21", "positive"=>{"count"=>0, "percent"=>0}, "potential"=>{"count"=>1, "percent"=>100}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>1}},
        {"date"=>"2015-01-19", "positive"=>{"count"=>1, "percent"=>100}, "potential"=>{"count"=>0, "percent"=>0}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>1}}
        ] )
    end

  end

  #---------------------------------------------------------------------------=

  describe "#timeseries" do
    it "raises an error if neighborhoods are missing" do
      get :timeseries, :neighborhoods => "[]", :unit => "daily"
      expect(JSON.parse(response.body)["message"]).to eq("Debe seleccionar al menos un comunidad")
    end

    it "returns correct timeseries" do
      get :timeseries, :neighborhoods => "[#{neighborhood.id}]", :unit => "daily", :format => :json
      visits = JSON.parse(response.body)

      [0, 1, 2, 3].each do |index|
        visits[index]["positive"].delete("locations")
        visits[index]["potential"].delete("locations")
        visits[index]["negative"].delete("locations")
      end

      expect(visits).to eq(
        [
          {"date"=>"2014-10-21", "positive"=>{"count"=>0, "percent"=>0}, "potential"=>{"count"=>1, "percent"=>50}, "negative"=>{"count"=>1, "percent"=>50}, "total"=>{"count"=>2}},
          {"date"=>"2015-01-19", "positive"=>{"count"=>1, "percent"=>100}, "potential"=>{"count"=>0, "percent"=>0}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>1}},
          {"date"=>"2015-01-28", "positive"=>{"count"=>1, "percent"=>50}, "potential"=>{"count"=>2, "percent"=>100}, "negative"=>{"count"=>0, "percent"=>0}, "total"=>{"count"=>2}},
          {"date"=>"2015-01-29", "positive"=>{"count"=>0, "percent"=>0}, "potential"=>{"count"=>0, "percent"=>0}, "negative"=>{"count"=>1, "percent"=>100}, "total"=>{"count"=>1}}
        ]
      )
    end

    it "returns the correct location addresses" do
      get :timeseries, :neighborhoods => [neighborhood.id].to_json, :unit => "daily", :format => :json
      visits = JSON.parse(response.body)

      expect(visits[0]["positive"]["locations"]).to eq([])
      expect(visits[0]["potential"]["locations"]).to eq([loc2.address])
      expect(visits[0]["negative"]["locations"]).to eq([loc.address])

      expect(visits[1]["positive"]["locations"]).to eq([loc2.address])
      expect(visits[1]["potential"]["locations"]).to eq([])
      expect(visits[1]["negative"]["locations"]).to eq([])


      expect(visits[2]["positive"]["locations"]).to eq([loc.address])
      expect(visits[2]["potential"]["locations"]).to eq([loc3.address, loc.address])
      expect(visits[2]["negative"]["locations"]).to eq([])


      expect(visits[3]["positive"]["locations"]).to eq([])
      expect(visits[3]["potential"]["locations"]).to eq([])
      expect(visits[3]["negative"]["locations"]).to eq([loc.address])
    end

    it "returns only those locations associated with the neighborhood" do
      location = create(:location, :address => "Address")
      r = build_stubbed(:positive_report, :location_id => location.id, :created_at => date4, :neighborhood_id => location.neighborhood_id)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)

      get :timeseries, :neighborhoods => [location.neighborhood_id].to_json, :timeframe => "-1", :unit => "daily", :format => :json
      expect(JSON.parse(response.body)).to eq([
        {
          "date"=>"2015-01-29",
          "positive"=>{"count"=>1, "percent"=>100, "locations" => [location.address]},
          "potential"=>{"count"=>0, "percent"=>0,  "locations" => []},
          "negative"=>{"count"=>0, "percent"=> 0, "locations" => []},
          "total"=>{"count"=>1}
        }
      ])
    end

    describe "Fetching CSV format" do
      it "returns proper format" do
        get :timeseries, :neighborhoods => [neighborhood.id].to_json, :timeframe => "-1", :unit => "daily", :format => :csv
        expect(response.headers["Content-Type"]).to eq("text/csv")
      end

      it "returns proper filename" do
        get :timeseries, :neighborhoods => [neighborhood.id].to_json, :timeframe => "-1", :unit => "daily", :format => :csv
        expect(response.headers["Content-Disposition"]).to include(neighborhood.name.downcase.gsub(" ", "_"))
      end

      it "returns proper header" do
        get :timeseries, :neighborhoods => [neighborhood.id].to_json, :timeframe => "-1", :unit => "daily", :format => :csv
        raw_csv = response.body
        csv     = CSV.parse(raw_csv)
        expect(csv[0]).to eq(["Fecha de visita", "Lugares visitados", "Lugares positivos", "Lugares potenciales", "Lugares negativos", "Lugares positivos (%)", "Lugares potenciales (%)", "Lugares sin criaderos (%)", "Dirección de lugares positivos", "Dirección de lugares potenciales", "Dirección de lugares negativos"])
      end

      it "returns proper content" do
        get :timeseries, :neighborhoods => [neighborhood.id].to_json, :timeframe => "-1", :unit => "daily", :format => :csv
        raw_csv = response.body
        csv     = CSV.parse(raw_csv)
        expect(csv.last).to eq(["2015-01-29", "1", "0", "0", "1", "0", "0", "100", "", "", "Test address"])
      end
    end


  end


end
