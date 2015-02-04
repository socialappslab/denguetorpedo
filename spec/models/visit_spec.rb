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
      v = Visit.first
      expect(v.identification_type).to eq(Report::Status::POSITIVE)
    end

    it "sets the correct identification type on potential reports" do
      report = FactoryGirl.create(:potential_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
      expect(v.identification_type).to eq(Report::Status::POTENTIAL)
    end

    it "sets the correct identification type on negative reports" do
      report = FactoryGirl.create(:negative_report, :location_id => location.id, :reporter => user, :created_at => created_at)
      v = Visit.first
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
    let(:second_location)       { FactoryGirl.create(:location, :address => "New Test address")}
    let(:locations) { [location, second_location] }
    let!(:hundred_days_ago)     { DateTime.parse("2014-10-21 11:00") }
    let!(:ten_days_ago)         { DateTime.parse("2015-01-19 11:00") }
    let!(:twenty_six_hours_ago) { DateTime.parse("2015-01-28 11:00") }
    let!(:fifteen_hours_ago)    { DateTime.parse("2015-01-29 11:00") }

    before(:each) do
      [hundred_days_ago, ten_days_ago, twenty_six_hours_ago].each_with_index do |created_at, index|

        if created_at == hundred_days_ago
          FactoryGirl.create(:visit,
          :visit_type => Visit::Types::INSPECTION,
          :identification_type => Report::Status::NEGATIVE,
          :location_id => location.id,
          :visited_at => created_at)
        else
          FactoryGirl.create(:visit,
          :visit_type => Visit::Types::INSPECTION,
          :identification_type => Report::Status::POSITIVE,
          :location_id => location.id,
          :visited_at => created_at)
        end

        # Create a visit for a location unless it's a specific index (for variety)
        if created_at != ten_days_ago
          FactoryGirl.create(:visit,
          :visit_type => Visit::Types::INSPECTION,
          :identification_type => Report::Status::POTENTIAL,
          :location_id => second_location.id,
          :visited_at => created_at)
        end
      end

      # The last visit should have a followup that results in elimination.
      v = Visit.order("visited_at DESC").first
      FactoryGirl.create(:visit, :visit_type => Visit::Types::FOLLOWUP, :identification_type => Report::Status::NEGATIVE, :location_id => location.id, :visited_at => fifteen_hours_ago)
    end

    it "returns one time-series point for each date" do
      expect(Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations).count).to eq(4)
      expect(Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations).count).to eq(4)
    end

    it "doesn't add duplicate date to time series" do
      # Let's create a visit 100 days ago to the second location. We're
      # going to ensure that there's only one time point with hundred_days_ago.strftime.
      FactoryGirl.create(:visit,
      :visit_type => Visit::Types::INSPECTION,
      :identification_type => Report::Status::POSITIVE,
      :location_id => second_location.id,
      :visited_at => hundred_days_ago)

      date_key = hundred_days_ago.strftime("%Y-%m-%d")
      time_series = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
      expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)

      time_series = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
      expect(time_series.find_all {|ts| ts[:date] == date_key}.length).to eq(1)
    end

    it "orders points by visited_at in ascending order" do
      visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
      expect(visits.first[:date]).to eq( hundred_days_ago.strftime("%Y-%m-%d") )
      expect(visits.last[:date]).to  eq( fifteen_hours_ago.strftime("%Y-%m-%d") )

      visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
      expect(visits.first[:date]).to eq( hundred_days_ago.strftime("%Y-%m-%d") )
      expect(visits.last[:date]).to  eq( fifteen_hours_ago.strftime("%Y-%m-%d") )
    end

    #--------------------------------------------------------------------------

    describe "for Daily percentage relative to houses visited on a date" do
      it "returns the correct time-series" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50}
          },
          {
            :date=>"2015-01-19",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}
          },
          {
            :date=>"2015-01-28",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>50}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>0, :percent=>0}
          },
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100}
          }
        ])
      end

      it "returns only follow-up time series" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::FOLLOWUP])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100}
          }
        ])
      end

      it "returns only inspection time series" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::INSPECTION])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50}
          },
          {
            :date=>"2015-01-19",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0}
          },
          {
            :date=>"2015-01-28",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>50}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>0, :percent=>0}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, DateTime.parse("2015-01-29 00:00"), [])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100}
          }
        ])
      end


    end


    #--------------------------------------------------------------------------

    describe "for Cumulative percentage relative to all houses visited" do
      it "returns the correct time-series for cumulative percentage" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations)
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50}
          },
          {
            :date=>"2015-01-19",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>33}, :potential=>{:count=>1, :percent=>33}, :negative=>{:count=>1, :percent=>33}
          },
          {
            :date=>"2015-01-28",
            :matching_visit_type=>true,
            :positive=>{:count=>2, :percent=>40}, :potential=>{:count=>2, :percent=>40}, :negative=>{:count=>1, :percent=>20}
          },
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>2, :percent=> 33}, :potential=>{:count=>2, :percent=> 33}, :negative=>{:count=>2, :percent=> 33}
          }
        ])
      end


      it "returns only follow-up time series" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::FOLLOWUP])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>2, :percent=> 33}, :potential=>{:count=>2, :percent=> 33}, :negative=>{:count=>2, :percent=> 33}
          }
        ])
      end

      it "returns only inspection time series" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, nil, [Visit::Types::INSPECTION])
        expect(visits).to eq([
          {
            :date=>"2014-10-21",
            :matching_visit_type=>true,
            :positive=>{:count=>0, :percent=>0}, :potential=>{:count=>1, :percent=>50}, :negative=>{:count=>1, :percent=>50}
          },
          {
            :date=>"2015-01-19",
            :matching_visit_type=>true,
            :positive=>{:count=>1, :percent=>33}, :potential=>{:count=>1, :percent=>33}, :negative=>{:count=>1, :percent=>33}
          },
          {
            :date=>"2015-01-28",
            :matching_visit_type=>true,
            :positive=>{:count=>2, :percent=>40}, :potential=>{:count=>2, :percent=>40}, :negative=>{:count=>1, :percent=>20}
          }
        ])
      end

      it "returns truncated time series when start time is set" do
        visits = Visit.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, DateTime.parse("2015-01-29 00:00"), [])
        expect(visits).to eq([
          {
            :date=>"2015-01-29",
            :matching_visit_type=>true,
            :positive=>{:count=>2, :percent=>33}, :potential=>{:count=>2, :percent=>33}, :negative=>{:count=>2, :percent=>33}
          }
        ])
      end
    end

    #-----------------------------------------------------------------------------

  end

  #-----------------------------------------------------------------------------

end
