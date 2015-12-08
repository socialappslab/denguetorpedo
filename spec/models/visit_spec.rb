# -*- encoding : utf-8 -*-

require "rails_helper"

describe Visit do
  let!(:created_at)    { Time.zone.now - 100.days }
  let!(:eliminated_at) { Time.zone.now - 3.days }
  let(:photo)          { Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg') }
  let(:location)       { create(:location, :address => "Test address")}
  let(:user)           { create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:report)         { create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)}

  describe "filter_time_series_from_date" do
    let(:daily_stats) {[
      {:date=>"2014-02-24"},
      {:date=>"2014-03-01"},
      {:date=>"2015-01-01"},
      {:date=>"2015-01-15"}
    ]}

    it "returns original daily stats if no start_time is passed" do
      result = Visit.filter_time_series_by_range(daily_stats, nil, nil, "daily")
      expect(result.count).to eq(4)
    end

    it "returns truncated daily stats for valid start time" do
      result = Visit.filter_time_series_by_range(daily_stats, Time.zone.parse("2014-02-26"), nil, "daily")
      expect(result.count).to eq(3)
    end

    it "returns truncated daily stats for valid end time" do
      result = Visit.filter_time_series_by_range(daily_stats, Time.zone.parse("2014-02-26"), Time.zone.parse("2014-12-31"), "daily")
      expect(result.count).to eq(1)
    end

    it "returns truncated daily stats for valid month" do
      result = Visit.filter_time_series_by_range(daily_stats, Time.zone.parse("2015-01-01"), nil, "monthly")
      expect(result.count).to eq(2)
    end

    it "returns truncated daily stats for valid daily" do
      result = Visit.filter_time_series_by_range(daily_stats, Time.zone.parse("2015-01-01"), nil, "daily")
      expect(result.count).to eq(2)
    end

    it "returns truncated daily stats for valid daily" do
      result = Visit.filter_time_series_by_range(daily_stats, Time.zone.parse("2014-12-30"), nil, "daily")
      expect(result.count).to eq(2)
    end



  end

  #-----------------------------------------------------------------------------

  context "when a new report is created", :after_commit => true do
    it "sets the correct visit time" do
      report = create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = report.find_or_create_visit_for_date(report.created_at)
      report.update_inspection_for_visit(v)
      v = Visit.first
      expect(v.visited_at).to eq(created_at)
    end

    it "sets the correct location" do
      report = create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = report.find_or_create_visit_for_date(report.created_at)
      report.update_inspection_for_visit(v)
      v = Visit.first
      expect(v.location_id).to eq(location.id)
    end

    it "sets the correct identification type on positive reports" do
      r = create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
      ins = Inspection.last
      expect(ins.identification_type).to eq(Report::Status::POSITIVE)
    end

    it "sets the correct identification type on potential reports" do
      r = create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
      v = Inspection.last
      expect(v.identification_type).to eq(Report::Status::POTENTIAL)
    end

    it "sets the correct identification type on negative reports" do
      r = create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
      v = Inspection.last
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end
  end

  #-----------------------------------------------------------------------------

  context "When an existing report is eliminated", :after_commit => true do
    let!(:eliminated_at) { Time.zone.now - 3.days }
    let(:report) { create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at) }

    before(:each) do
      # This invokes after_commit callback to create a Visit instance.
      report.save
      v = report.find_or_create_visit_for_date(report.created_at)
      report.update_inspection_for_visit(v)


      # This eliminates the report.
      report.after_photo   				 = photo
      report.elimination_method_id = report.breeding_site.elimination_methods.first.id
      report.completed_at          = Time.zone.now
      report.eliminator_id 				 = user.id
      report.eliminated_at 				 = eliminated_at
    end

    it "sets the correct visit time" do
      report.find_or_create_visit_for_date(report.eliminated_at)
      expect(Visit.last.visited_at).to eq(report.eliminated_at)
    end

    it "sets the correct location" do
      report.save
      v = report.find_or_create_visit_for_date(report.eliminated_at)
      report.update_inspection_for_visit(v)
      v = Visit.last
      expect(v.location_id).to eq(report.location.id)
    end

    it "sets the correct identification type" do
      report.save
      v = report.find_or_create_visit_for_date(report.eliminated_at)
      report.update_inspection_for_visit(v)
      v = Visit.last
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end
  end

  #-----------------------------------------------------------------------------

  # These tests test for very special cases that can be called "gotchas".
  #
  describe "Special cases for calculating time-series" do
    let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
    let!(:date2)    { DateTime.parse("2015-01-19 11:00") }

    # In this case, consider a location that was visited on T1 and was negative,
    # but at T2 was classified as positive. We want to make sure that its
    # classification on T1 is negative, even though there is an inspection with status
    # positive on T2.
    it "does not include future data of inspections before a certain date for daily percentages" do
      r = create(:negative_report, :reporter_id => user.id, :location_id => location.id, :created_at => date1)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
      r = create(:positive_report, :reporter_id => user.id, :location_id => location.id, :created_at => date2)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)

      visits = Visit.calculate_time_series_for_locations([location], nil, nil, "daily")
      visits.map {|v| v.delete(:total)}
      expect(visits).to eq([
        {
          :date=>"2014-10-21",
          :positive=>{:count=>0, :percent=>0, :locations => []},
          :potential=>{:count=>0, :percent=>0, :locations => []},
          :negative=>{:count=>1, :percent=>100, :locations => [location.id]},
        },
        {
          :date=>"2015-01-19",
          :positive=>{:count=>1, :percent=>100, :locations => [location.id]},
          :potential=>{:count=>0, :percent=>0, :locations => []},
          :negative=>{:count=>0, :percent=>0, :locations => []},
        }
      ])
    end

    it "counts a Visit without inspections (usual when the location is marked N)" do
      r = create(:negative_report, :reporter_id => user.id, :location_id => location.id, :created_at => date1)
      v = r.find_or_create_visit_for_date(r.created_at)

      visits = Visit.calculate_time_series_for_locations([location], nil, nil, "daily")
      expect(visits[0][:negative][:count]).to eq(1)
    end
  end

  #-----------------------------------------------------------------------------

  describe "associated visits", :after_commit => true do
    let(:locations) { [location] }
    let!(:date1)    { DateTime.parse("2014-11-15 11:00") }
    let!(:date2)    { DateTime.parse("2014-11-20 11:00") }

    it "calculates identification type without consider past day's reports" do
      r = create(:full_report, :reporter_id => user.id, :location_id => location.id, :larvae => true,    :created_at => date1)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)
      r = create(:full_report, :reporter_id => user.id, :location_id => location.id, :protected => true, :created_at => date2)
      v = r.find_or_create_visit_for_date(r.created_at)
      r.update_inspection_for_visit(v)

      visits = Visit.calculate_time_series_for_locations(locations, nil, nil, "daily")
      visits.map {|v| v.delete(:total)}
      expect(visits).to eq([
        {
          :date=>"2014-11-15",
          :positive  => { :count => 1, :percent => 100, :locations => [location.id] },
          :potential => { :count => 0, :percent => 0,   :locations => [] },
          :negative  => { :count => 0, :percent => 0,   :locations => [] }
        },
        {
          :date      => "2014-11-20",
          :positive  => {:count=>0, :percent=>0,   :locations =>[]},
          :potential => {:count=>0, :percent=>0,   :locations =>[]},
          :negative  => {:count=>1, :percent=>100, :locations => [location.id]}
        }
      ])
    end
  end

  #-----------------------------------------------------------------------------

  describe "Calculating time-series", :after_commit => true do
    let!(:loc2)       { create(:location, :address => "New Test address")}
    let!(:loc3)       { create(:location, :address => "New Test address again")}
    let!(:loc4)       { create(:location, :address => "New Test address 3")}
    let(:locations) { [location, loc2, loc3, loc4] }
    let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
    let!(:date2)    { DateTime.parse("2015-01-19 11:00") }
    let!(:date3)    { DateTime.parse("2015-01-28 11:00") }
    let!(:date4)    { DateTime.parse("2015-01-29 11:00") }

    before(:each) do
      [
        [:negative_report, location, date1],
        [:potential_report, loc2, date1],
        [:positive_report, loc2, date2],
        [:positive_report, location, date3],
        [:potential_report, location, date3],
        [:potential_report, loc3, date3],
      ].each do |h|
        type_of_report = h[0]
        loc_value       = h[1]
        date           = h[2]

        r = build_stubbed(type_of_report, :location_id => loc_value.id, :created_at => date)
        v = r.find_or_create_visit_for_date(r.created_at)
        r.update_inspection_for_visit(v)
      end

      pos_report = build_stubbed(:positive_report, :location_id => location.id, :created_at => date3)
      pos_report.completed_at  = date4
      pos_report.eliminated_at = date4
      pos_report.elimination_method_id = 1
      v = pos_report.find_or_create_visit_for_date(date4)
      pos_report.update_inspection_for_visit(v)
    end

    it "returns one time-series point for each date" do
      expect(Visit.calculate_time_series_for_locations(locations, nil, nil, "daily").count).to eq(4)
    end

    it "doesn't add duplicate date to time series" do
      # Let's create a visit 100 days ago to the second location. We're
      # going to ensure that there's only one time point with date1.strftime.
      create(:positive_report, :reporter_id => user.id, :location_id => loc2.id, :created_at => date1)
      # create(:visit,
      # :visit_type => Visit::Types::INSPECTION,
      # :identification_type => Report::Status::POSITIVE,
      # :location_id => loc2.id,
      # :visited_at => date1)

      date_key = date1.strftime("%Y-%m-%d")
      time_series = Visit.calculate_time_series_for_locations(locations, nil, nil, "daily")
      expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)

      # time_series = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
      # expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)
    end

    it "orders points by visited_at in ascending order" do
      visits = Visit.calculate_time_series_for_locations(locations, nil, nil, "daily")
      expect(visits.first[:date]).to eq( date1.strftime("%Y-%m-%d") )
      expect(visits.last[:date]).to  eq( date4.strftime("%Y-%m-%d") )
    end

    #--------------------------------------------------------------------------

    # The distribution of houses is as follows:
    # First date had 2 visits to 2 (first and second) locations (first negative, second potential)
    # Second date had 1 visit to second location (second positive)
    # Third date had 2 visits to 2 (first and third) locations (first positive and third potential)
    # Fourth date had 1 visit to first location (first negative)

    describe "for Daily percentage relative to houses visited on a date" do
      it "returns the correct time-series" do
        visits = Visit.calculate_time_series_for_locations(locations, nil, nil, "daily")
        visits.map {|v| v.delete(:total)}
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0, :locations => []},
            :potential=>{:count=>1, :percent=>50, :locations => [loc2.id]},
            :negative=>{:count=>1, :percent=>50, :locations => [location.id]}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>1, :percent=>100, :locations => [loc2.id]},
            :potential=>{:count=>0, :percent=>0, :locations => []},
            :negative=>{:count=>0, :percent=>0, :locations => []}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>1, :percent=>50, :locations => [location.id]},
            :potential=>{:count=>2, :percent=>100, :locations => [location.id, loc3.id]},
            :negative=>{:count=>0, :percent=>0, :locations => []}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0, :locations => []},
            :potential=>{:count=>0, :percent=>0, :locations => []},
            :negative=>{:count=>1, :percent=>100, :locations => [location.id]}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_time_series_for_locations(locations, Time.zone.parse("2015-01-29"), nil, "daily" )
        visits.map {|v| v.delete(:total)}
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0,   :locations => []},
            :potential=>{:count=>0, :percent=>0,  :locations => []},
            :negative=>{:count=>1, :percent=>100, :locations => [location.id]}
          }
        ])
      end

      it "returns empty if time series contains no data since specified start time" do
        visits = Visit.calculate_time_series_for_locations(locations, Time.zone.parse("2015-02-01"), nil, "daily" )
        expect(visits).to eq([])
      end
    end

    #--------------------------------------------------------------------------

    describe "for Monthly percentage relative to houses visited on a date" do
      it "returns the correct time-series" do
        visits = Visit.calculate_time_series_for_locations(locations, nil, nil, "monthly")
        visits.map {|v| v.delete(:total)}
        expect(visits).to eq([
          {
            :date=>"2014-10",
            :positive=>{:count=>0, :percent=>0,  :locations => []},
            :potential=>{:count=>1, :percent=>50, :locations => [loc2.id]},
            :negative=>{:count=>1, :percent=>50, :locations => [location.id]}
          },
          {
            :date=>"2015-01",
            :positive=>{:count=>2, :percent=>67, :locations => [loc2.id, location.id]},
            :potential=>{:count=>2, :percent=>67, :locations => [location.id, loc3.id]},
            :negative=>{:count=>1, :percent=>33, :locations => [location.id]}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_time_series_for_locations(locations, DateTime.parse("2015-01-29 00:00"), nil, "monthly")

        visits.map {|v| v.delete(:total)}
        expect(visits).to eq([
          {
            :date=>"2015-01",
            :positive=>{:count=>2, :percent=>67,  :locations => [loc2.id, location.id]},
            :potential=>{:count=>2, :percent=>67, :locations => [location.id, loc3.id]},
            :negative=>{:count=>1, :percent=>33,  :locations => [location.id]}
          }
        ])
      end

      it "returns empty if time series contains no data since specified start time" do
        visits = Visit.calculate_time_series_for_locations(locations, Time.zone.parse("2015-02-01"), nil, "monthly")
        expect(visits).to eq([])
      end
    end
  end

  #-----------------------------------------------------------------------------

end
