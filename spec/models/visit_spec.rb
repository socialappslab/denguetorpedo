# encoding: utf-8

require 'spec_helper'

describe Visit do
  let!(:created_at)    { Time.now - 100.days }
  let!(:eliminated_at) { Time.now - 3.days }
  let(:photo)          { Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg') }
  let(:location)       { FactoryGirl.create(:location, :address => "Test address")}
  let(:user)           { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:report)         { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)}


  #-----------------------------------------------------------------------------

  context "when a new report is created", :after_commit => true do
    it "creates a new visit instance" do
      expect {
        FactoryGirl.create(:report, :location_id => location.id, :reporter => user)
      }.to change(Visit, :count).by(1)
    end

    it "creates a new inspection instance" do
      expect {
        FactoryGirl.create(:report, :location_id => location.id, :reporter => user)
      }.to change(Inspection, :count).by(1)
    end

    it "sets the correct visit time" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.visited_at).to eq(created_at)
    end

    it "sets the correct visit type" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.visit_type).to eq(Visit::Types::INSPECTION)
    end

    it "sets the correct location" do
      report = FactoryGirl.create(:report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.location_id).to eq(location.id)
    end

    it "sets the correct identification type on positive reports" do
      report = FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      ins = Inspection.last
      expect(ins.identification_type).to eq(Report::Status::POSITIVE)
    end

    it "sets the correct identification type on potential reports" do
      report = FactoryGirl.create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Inspection.last
      expect(v.identification_type).to eq(Report::Status::POTENTIAL)
    end

    it "sets the correct identification type on negative reports" do
      report = FactoryGirl.create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Inspection.last
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end

    it "updates an existing visit if a visit already exists" do
      report.save
      expect {
        FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  context "When an existing report is eliminated", :after_commit => true do
    let!(:eliminated_at) { Time.now - 3.days }
    let(:report) { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at) }

    before(:each) do
      # This invokes after_commit callback to create a Visit instance.
      report.save

      # This eliminates the report.
      report.after_photo   				 = photo
      report.elimination_method_id = report.breeding_site.elimination_methods.first.id
      report.completed_at          = Time.now
      report.eliminator_id 				 = user.id
      report.eliminated_at 				 = eliminated_at
    end

    it "creates a new visit instance" do
      expect {
        report.save
      }.to change(Visit, :count).by(1)
    end

    it "sets the correct visit time" do
      report.save
      v = Visit.last
      expect(v.visited_at).to eq(eliminated_at)
    end

    it "sets the correct visit type" do
      report.save
      v = Visit.last
      expect(v.visit_type).to eq(Visit::Types::FOLLOWUP)
    end

    it "sets the correct location" do
      report.save
      v = Visit.last
      expect(v.location_id).to eq(report.location.id)
    end

    it "sets the correct identification type" do
      report.save
      v = Visit.last
      expect(v.identification_type).to eq(Report::Status::NEGATIVE)
    end

    it "updates an existing visit if a visit already exists" do
      expect {
        FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  describe "Calculating identification type", :after_commit => true do
    let(:positive_report)  { FactoryGirl.create(:positive_report, :location_id => location.id, :reporter => user, :created_at => created_at)}
    let(:potential_report) { FactoryGirl.create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)}
    let(:negative_report)  { FactoryGirl.create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)}

    it "returns positive if report is positive" do
      v = Visit.new
      status  = positive_report.original_status
      reports = positive_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::POSITIVE)
    end

    it "returns potential if report is potential" do
      v = Visit.new

      status  = potential_report.original_status
      reports = potential_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::POTENTIAL)
    end

    it "returns negative if report is negative" do
      v = Visit.new

      status  = negative_report.original_status
      reports = negative_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::NEGATIVE)
    end

    it "returns positive if at least one report is positive" do
      positive_report.save
      v = Visit.last

      status  = negative_report.original_status
      reports = negative_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::POSITIVE)
    end

    it "returns potential if no positives and at least one report is potential" do
      potential_report.save
      v = Visit.last

      status  = negative_report.original_status
      reports = negative_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::POTENTIAL)
    end

    it "returns negative if no positives and no potential" do
      v = Visit.new

      status  = negative_report.original_status
      reports = negative_report.location.reports
      expect(v.calculate_identification_type_from_status_and_reports(status, reports)).to eq(Report::Status::NEGATIVE)
    end
  end

  #-----------------------------------------------------------------------------

  describe "Calculating time-series", :after_commit => true do
    let!(:second_location)       { FactoryGirl.create(:location, :address => "New Test address")}
    let!(:third_location)       { FactoryGirl.create(:location, :address => "New Test address again")}
    let!(:fourth_location)       { FactoryGirl.create(:location, :address => "New Test address 3")}
    let(:locations) { [location, second_location, third_location, fourth_location] }
    let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
    let!(:date2)    { DateTime.parse("2015-01-19 11:00") }
    let!(:date3)    { DateTime.parse("2015-01-28 11:00") }
    let!(:date4)    { DateTime.parse("2015-01-29 11:00") }

    before(:each) do
      # The distribution of houses is as follows:
      # First date had 2 visits to 2 (first and second) locations (first negative, second potential)
      # Second date had 1 visit to second location (second positive)
      # Third date had 2 visits to 2 (first and third) locations (first positive and third potential)
      # Fourth date had 1 visit to first location (first negative)
      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION, :identification_type => Report::Status::NEGATIVE,
      :location_id => location.id, :visited_at => date1)
      FactoryGirl.create(:visit, :visit_type => Visit::Types::INSPECTION,
      :identification_type => Report::Status::POTENTIAL,
      :location_id => second_location.id, :visited_at => date1)

      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION, :identification_type => Report::Status::POSITIVE,
      :location_id => second_location.id, :visited_at => date2)

      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION, :identification_type => Report::Status::POSITIVE,
      :location_id => location.id, :visited_at => date3)
      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION, :identification_type => Report::Status::POTENTIAL,
      :location_id => third_location.id, :visited_at => date3)

      v = Visit.order("visited_at DESC").first
      FactoryGirl.create(:visit, :visit_type => Visit::Types::FOLLOWUP, :identification_type => Report::Status::NEGATIVE, :location_id => location.id, :visited_at => date4)
    end

    it "returns one time-series point for each date" do
      expect(Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations).count).to eq(4)
      expect(Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations).count).to eq(4)
    end

    it "doesn't add duplicate date to time series" do
      # Let's create a visit 100 days ago to the second location. We're
      # going to ensure that there's only one time point with date1.strftime.
      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION,
      :identification_type => Report::Status::POSITIVE,
      :location_id => second_location.id,
      :visited_at => date1)

      date_key = date1.strftime("%Y-%m-%d")
      time_series = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
      expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)

      time_series = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
      expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)
    end

    it "orders points by visited_at in ascending order" do
      visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
      expect(visits.first[:date]).to eq( date1.strftime("%Y-%m-%d") )
      expect(visits.last[:date]).to  eq( date4.strftime("%Y-%m-%d") )

      visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
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
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50},
            :total => {:count => 2}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 1}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>1, :percent=>50}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 2}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100},
            :total => {:count => 1}
          }
        ])
      end

      it "returns only follow-up time series" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::FOLLOWUP])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 0}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 0}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 0}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100},
            :total => {:count => 1}
          }
        ])
      end

      it "returns only inspection time series" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::INSPECTION])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50},
            :total => {:count => 2}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 1}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>1, :percent=>50}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 2}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 0}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, DateTime.parse("2015-01-29 00:00"), [])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100},
            :total => {:count => 1}
          }
        ])
      end


    end


    #--------------------------------------------------------------------------

    # The distribution of houses is as follows:
    # First date had 2 visits to 2 (first and second) locations (first negative, second potential)
    # Second date had 1 visit to second location (second positive)
    # Third date had 2 visits to 2 (first and third) locations (first positive and third potential)
    # Fourth date had 1 visit to first location (first negative)

    describe "for Cumulative percentage relative to all houses visited" do
      it "returns the correct time-series for cumulative percentage" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>25}, :negative=>{:count=>1, :percent=>25},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>1, :percent=>25}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>25},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>2, :percent=>50}, :potential=>{:count=>1, :percent=>25}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>1, :percent=> 25}, :potential=>{:count=>1, :percent=> 25}, :negative=>{:count=>1, :percent=> 25},
            :total => {:count => 4}
          }
        ])
      end


      it "returns only follow-up time series" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::FOLLOWUP])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=> 0}, :potential=>{:count=>0, :percent=> 0}, :negative=>{:count=>1, :percent=> 25},
            :total => {:count => 4}
          }
        ])
      end

      it "returns only inspection time series" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::INSPECTION])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>25}, :negative=>{:count=>1, :percent=>25},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-19",
            :positive=>{:count=>1, :percent=>25}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>25},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-28",
            :positive=>{:count=>2, :percent=>50}, :potential=>{:count=>1, :percent=>25}, :negative=>{:count=>0, :percent=>0},
            :total => {:count => 4}
          },
          {
            :date=>"2015-01-29",
            :positive=>{:count=>0, :percent=> 0}, :potential=>{:count=>0, :percent=> 0}, :negative=>{:count=>0, :percent=> 0},
            :total => {:count => 4}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, DateTime.parse("2015-01-29 00:00"), [])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :positive=>{:count=>1, :percent=> 25}, :potential=>{:count=>1, :percent=> 25}, :negative=>{:count=>1, :percent=> 25},
            :total => {:count => 4}
          }
        ])
      end
    end

    #-----------------------------------------------------------------------------

  end

  #-----------------------------------------------------------------------------

end
