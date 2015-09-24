require "sidekiq"
include GreenLocationWeeklySeries

# This method runs every day and updates the Redis datastore responsible for
# calculating green location rankings.
class GreenLocationSeriesWorker
  include Sidekiq::Worker
  include GreenLocationRankings

  sidekiq_options :queue => :timeseries, :retry => true, :backtrace => true

  def perform
    Time.use_zone("America/Guatemala") do
      time = Time.zone.now.end_of_week
    end

    green_locs = Location.all.find_all {|loc| loc.green?}
    GreenLocationWeeklySeries.add_green_houses_to_date(green_locs.count, time)
    GreenLocationSeriesWorker.perform_in(1.week)
  end
end
