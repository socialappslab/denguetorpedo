# This module abstracts the notion of a green locations rankings table by
# using Redis in-memory datastore to store rankings. Use this method
# to retrieve top 5 results, and use this method to periodically store
# new rankings (run via a Sidekiq job).

module LocationTimeSeries
  def self.add_status_to_visit_date(neighborhood, location, status, visit_date)
    score         = self.format_date(visit_date).to_i
    unique_string = "#{score}:#{status}"

    $redis_pool.with do |redis|
      redis.zadd(self.redis_key(neighborhood, location), score, unique_string)
    end
  end

  def self.timeseries_from_to(neighborhood, location, start_date, end_date)
    start_score = self.format_date(start_date)
    end_score   = self.format_date(end_date)

    timeseries = []
    $redis_pool.with do |redis|
      timeseries = redis.zrevrangebyscore(self.redis_key(neighborhood, location), end_score, start_score, :with_scores => true)
    end

    return timeseries
  end

  def self.parsed_timeseries_for_locations_from_to(neighborhood, locations, start_date, end_date)
    raw_timeseries = []
    locations.each do |location|
      raw_timeseries += self.timeseries_from_to(neighborhood, location, start_date, end_date)
    end

    series = []
    raw_timeseries.each do |rts|
      visit_date = rts[1].to_i
      status     = rts[0].split(":")[1].to_i

      existing_series = series.find {|pts| pts[:date] == visit_date}
      if existing_series.blank?
        existing_series = {
          :date       => visit_date,
          :positive   => {:count => 0, :percent => 0},
          :potential  => {:count => 0, :percent => 0},
          :negative   => {:count => 0, :percent => 0},
          :total      => {:count => 0}
        }
        series << existing_series
      end

      if status == Inspection::Types::POSITIVE
        existing_series[:positive][:count] += 1
      elsif status == Inspection::Types::POTENTIAL
        existing_series[:potential][:count] += 1
      else
        existing_series[:negative][:count] += 1
      end
      existing_series[:total][:count] += 1

      index         = series.find_index {|s| s[:date] == visit_date}
      series[index] = existing_series
    end

    series = Visit.calculate_percentages_for_time_series(series)
    return series

    # series = []
    # raw_timeseries.each do |t|
    #   visit_date = t[0].split(":")[0]
    #   status     = t[0].split(":")[1].to_i
    #
    #   existing_series = series.find {|s| s[:date] == visit_date}
    #   if existing_series.blank?
    #     existing_series = {
    #       :date       => visit_date,
    #       :positive   => {:count => 0, :percent => 0},
    #       :potential  => {:count => 0, :percent => 0},
    #       :negative   => {:count => 0, :percent => 0},
    #       :total      => {:count => 0}
    #     }
    #
    #     series << existing_series
    #   end
    #
    #   if status == Inspection::Types::POSITIVE
    #     existing_series[:positive][:count] += 1
    #   elsif status == Inspection::Types::POTENTIAL
    #     existing_series[:potential][:count] += 1
    #   else
    #     existing_series[:negative][:count] += 1
    #   end
    #   existing_series[:total][:count] += 1
    #
    #   index         = series.find_index {|s| s[:date] == visit_date}
    #   series[index] = existing_series
    # end
    #
    # series = Visit.calculate_percentages_for_time_series(series)
    # return series
  end

  def self.format_date(date)
    return date.strftime("%Y%m%d")
  end


  def self.redis_key(neighborhood, location)
    "neighborhoods:#{neighborhood.id}:locations:#{location.id}"
  end
end
