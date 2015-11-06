# -*- encoding : utf-8 -*-
require "rails_helper"

describe GreenLocationWeeklySeries do
  let(:community)  {create(:neighborhood)}
  let(:city)       {community.city}
  let(:user)       {build_stubbed(:user)}
  let(:start_time) {Time.parse("2015-10-01").beginning_of_week}
  let(:end_time)   {Time.parse("2015-11-09").end_of_week}

  before(:each) do
    $redis_pool = ConnectionPool.new(size: 1, timeout: 2) { Redis.new(:url => "redis://localhost:9736/") }
  end

  after(:each) do
    $redis_pool.with {|redis| redis.flushall }
  end

  it "adds and returns correct time series" do
    end_of_week = Time.parse("2015-11-08").end_of_week
    subject.add_green_houses_to_date(city, 100, end_of_week)

    series = subject.time_series_for_city(city, start_time, end_time)
    expect(series[0][:green_houses]).to eq("100")
    expect(series[0][:date].strftime("%Y-%m-%d")).to eq("2015-11-08")
  end
end
