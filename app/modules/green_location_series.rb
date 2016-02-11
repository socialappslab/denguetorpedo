# This module abstracts the notion of a weekly GreenLocation time series
# by using Redis to store weekly green location data.
# We do this as follows:
#   * We use sorted sets
#   * Score represents unique precision timestamp in form YYYYMMDD. The day of the
#     week is always the last day of the week.
#   * Element corresponds to number of green houses in a particular week.
# This is run in a Sidekiq job every week.

module GreenLocationSeries
  def self.add_green_houses_to_date(city, house_count, end_of_week)
    $redis_pool.with do |redis|
      formatted_date = self.format_date(end_of_week)
      redis.zadd(self.redis_key_for_city(city), formatted_date.to_i, "#{formatted_date}:#{house_count}" )
    end
  end

  def self.add_to_neighborhood_count(neighborhood, house_count, end_of_day)
    $redis_pool.with do |redis|
      formatted_date = self.format_date(end_of_day)

      # Before we add to the neighborhood, let's remove a matching date.
      matches = redis.zscan(self.redis_key_for_neighborhood(neighborhood), 0, {:match => "#{formatted_date}:*"})[-1]
      matches.each {|match| redis.zrem(self.redis_key_for_neighborhood(neighborhood), match[0]) }
      redis.zadd(self.redis_key_for_neighborhood(neighborhood), formatted_date.to_i, "#{formatted_date}:#{house_count}" )
    end
  end

  def self.get_latest_count_for_neighborhood(neighborhood)
    score = []

    $redis_pool.with do |redis|
      Time.use_zone("America/Guatemala") do
        # NOTE: We're using zrevrange here since it orders elements by highest (most recent week)
        # to lowest (a week six months ago). Any other way, and we would be searching many more elements.
        score = redis.zrevrange(self.redis_key_for_neighborhood(neighborhood), 0, 1).map do |val, score|
          val.split(":")[-1]
        end
      end
    end

    return score[0]
  end

  def self.time_series_for_city(city, start_time, end_time)
    time = start_time
    weeks = []
    while time <= end_time
      weeks << format_date(time).to_i
      time += 1.week
    end
    weeks.uniq!

    series = []
    $redis_pool.with do |redis|
      Time.use_zone("America/Guatemala") do
        # NOTE: We're using zrevrange here since it orders elements by highest (most recent week)
        # to lowest (a week six months ago). Any other way, and we would be searching many more elements.
        series = redis.zrevrange(self.redis_key_for_city(city), 0, weeks.count, :with_scores => true).map do |val, score|
          {:green_houses => val.split(":")[-1], :date => Time.zone.parse(score.to_i.to_s)}
        end
      end
    end

    return series
  end

  def self.format_date(date)
    return date.strftime("%Y%m%d")
  end

  def self.redis_key_for_city(city)
    "cities:#{city.id}:green_locations:timeseries:weekly"
  end

  def self.redis_key_for_neighborhood(neighborhood)
    "neighborhoods:#{neighborhood.id}:green_locations:timeseries:daily"
  end
end
