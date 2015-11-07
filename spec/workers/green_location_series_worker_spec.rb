# -*- encoding : utf-8 -*-
require "rails_helper"
require "timecop"

describe GreenLocationSeriesWorker do
  let(:user) 		  { create(:user) }
  let(:user2) 		{ create(:user) }
  let(:community) { create(:neighborhood)}
  let(:city)      { community.city }
  let(:green_loc) { create(:location, :address => "N123", :neighborhood => community) }
  let(:loc)       { create(:location, :address => "N456", :neighborhood => community) }

  before(:each) do
    # Create a green location belonging to a user.
    [1.year.ago, 5.months.ago, 1.month.ago].each do |time|
      r = create(:negative_report, :location_id => green_loc.id, :reporter_id => user.id)
      v = create(:visit, :location_id => green_loc.id, :visited_at => time)
      create(:inspection, :report_id => r.id, :visit_id => v.id, :identification_type => 2)
    end

    # We freeze the time in order to avoid a stack level too deep error.
    Sidekiq::Testing.fake!
  end

  after(:each) do
    GreenLocationSeriesWorker.jobs.clear
  end

  it "generates correct rankings for city" do
    skip "TODO: Day and end of day not working properly"
    Time.use_zone("America/Guatemala") do
      Timecop.travel(Time.zone.now.end_of_week)

      GreenLocationSeriesWorker.perform_async
      GreenLocationSeriesWorker.perform_one

      end_time   = Time.zone.now.end_of_week
      start_time = end_time - 6.months
      series     = GreenLocationSeries.time_series_for_city(city, start_time, end_time)

      expect(series[0][:green_houses]).to eq("1")
      expect(series[0][:date].strftime("%Y-%m-%d")).to eq("2015-11-08")

      Timecop.return
    end
  end

  it "generates correct rankings for neighborhood" do
    GreenLocationSeriesWorker.perform_async
    GreenLocationSeriesWorker.perform_one
    score = GreenLocationSeries.get_latest_count_for_neighborhood(community)
    expect(score).to eq(1)
  end

end
