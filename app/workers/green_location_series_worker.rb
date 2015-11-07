require "sidekiq"
include GreenLocationSeries

# This method runs every day and updates the Redis datastore responsible for
# calculating green location rankings.
class GreenLocationSeriesWorker
  include Sidekiq::Worker
  include GreenLocationRankings

  sidekiq_options :queue => :timeseries, :retry => true, :backtrace => true

  def perform
    Time.use_zone("America/Guatemala") do
      time = Time.zone.now.end_of_week

      City.find_each do |city|
        locids = city.neighborhoods.map {|n| n.locations.pluck(:id)}.flatten.uniq
        green_locs = Location.where(:id => locids).find_all {|loc| loc.green?}
        GreenLocationWeeklySeries.add_green_houses_to_date(city, green_locs.count, time)
      end

      GreenLocationSeriesWorker.perform_in(1.week)
    end
  end
end
