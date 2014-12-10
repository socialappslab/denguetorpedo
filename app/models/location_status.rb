class LocationStatus < ActiveRecord::Base
  attr_accessible :location_id, :status

  # The status of a location defines whether it's positive, potential, negative
  # or clean. The first three are defined by the associated reports at that
  # location, and the last one is separately set in the database. See the
  # 'status' instance method.
  module Types
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
    CLEAN     = 3
  end

  #----------------------------------------------------------------------------

  # Returns a hash of number of positive, potential, and negative
  # locations for each day. A location belongs to the closest end-of-day.
  # TODO: This looks like it can lend to a cleverly constructed SQL query...
  def self.segment_locations_by_day(locations)
    statuses = LocationStatus.where(:location_id => locations.map(&:id)).order("created_at DESC")

    daily_distribution = {}
    accounted_locations = []
    statuses.each do |status|
      key                = status.created_at.strftime("%Y-%m-%d")
      unique_daily_index = [key, status.location_id]

      # Exclude counting a status if its location has already been seen *for that day*.
      next if accounted_locations.include?(unique_daily_index)
      accounted_locations << unique_daily_index

      # Initialize the key if it hasn't been initialized yet.
      daily_distribution[key] ||= {}

      daily_distribution[key][status.status] ||= 0
      daily_distribution[key][status.status]  += 1
    end

    return daily_distribution
  end

  #----------------------------------------------------------------------------

  def self.calculate_affected_percentages_by_day(locations)
    statistics = []

    segments = self.segment_locations_by_day(locations)
    total = locations.count
    segments.each do |date, distribution|
      positive  = distribution[Types::POSITIVE]  || 0
      potential = distribution[Types::POTENTIAL] || 0
      negative  = distribution[Types::NEGATIVE]  || 0
      total     -= positive + potential + negative
      percent   = (positive + potential) / total.to_f
      statistics << [date, (percent * 100).to_i]
    end

    statistics = statistics.sort {|s1, s2| s1[0] <=> s2[0]}
    return statistics
  end

  #----------------------------------------------------------------------------

end
