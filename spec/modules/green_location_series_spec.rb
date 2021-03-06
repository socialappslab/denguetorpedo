# -*- encoding : utf-8 -*-
require "rails_helper"

describe GreenLocationSeries do
  let(:community)  {create(:neighborhood)}
  let(:city)       {community.city}
  let(:user)       {build_stubbed(:user)}
  let(:start_time) {Time.parse("2015-10-01").beginning_of_week}
  let(:end_time)   {Time.parse("2015-11-09").end_of_week}

  it "adds and returns correct time series for city" do
    end_of_week = Time.parse("2015-11-08").end_of_week
    subject.add_green_houses_to_date(city, 100, end_of_week)

    series = subject.time_series_for_city(city, start_time, end_time)
    expect(series[0][:green_houses]).to eq("100")
    expect(series[0][:date].strftime("%Y-%m-%d")).to eq("2015-11-08")
  end

  it "adds and returns correct time series for neighborhood" do
    time = Time.parse("2015-11-08").end_of_day
    subject.add_to_neighborhood_count(community, 100, time)

    score = subject.get_latest_count_for_neighborhood(community)
    expect(score).to eq("100")
  end
end
