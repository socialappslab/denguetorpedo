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

      City.find_each do |city|
        city_green_count = 0

        # Calculate and add number of green houses for each neighborhood. Keep
        # track of this number to append to city at the end.
        city.neighborhoods.each do |n|
          locids     = n.locations.pluck(:id).flatten.uniq
          green_locs = Location.where(:id => locids).find_all {|loc| loc.green?}
          GreenLocationSeries.add_to_neighborhood_count(n, green_locs.count, Time.zone.now.end_of_day)

          city_green_count += green_locs.count
        end

        # Append to the cities only if it's the last day of the week.
        puts "Time.zone.now.day: #{Time.zone.now}"
        puts "Time.zone.now.end_of_week.day: #{Time.zone.now.end_of_week}"
        if Time.zone.now.day == Time.zone.now.end_of_week.day
          GreenLocationSeries.add_green_houses_to_date(city, city_green_count, Time.zone.now.end_of_week)
        end
      end

      GreenLocationSeriesWorker.perform_in(1.day)
    end
  end
end
