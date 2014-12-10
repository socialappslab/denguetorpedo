# NOTE: The associated LocationStatus table stores a *daily* snapshot
# of the location's status. This means that if several reports are created in
# a day, then we will simply update the existing LocationStatus entry.
# This has two benefits:
# a) statistics are *much* faster to calculate
# b) there is no need for real-time location statuses.I went with real-time series before this,
#    and it was a hassle to calculate daily trends (which is all what people care about).
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

  def self.calculate_percentages_for_locations(locations)
    statuses = LocationStatus.where(:location_id => locations.map(&:id)).order("created_at ASC")
    return [] if statuses.blank?

    daily_stats = []
    first_day   = statuses.first.created_at
    last_day    = statuses.last.created_at
    day         = first_day

    # TODO: This is going to get expensive very soon and fast. We need to
    # leverage previous measurements to cumulatively add the stats.
    while day <= last_day
      key   = day.strftime("%Y-%m-%d")
      stats = statuses.where("DATE(created_at) <= ?", key)

      positive_count  = stats.find_all {|s| s.status == Types::POSITIVE}.count
      potential_count = stats.find_all {|s| s.status == Types::POTENTIAL}.count
      negative_count  = stats.find_all {|s| s.status == Types::NEGATIVE}.count
      clean_count     = stats.find_all {|s| s.status == Types::CLEAN}.count

      total   = positive_count + potential_count + negative_count + clean_count
      percent = (positive_count + potential_count).to_f / total
      neg_percent = (negative_count).to_f / total

      daily_stats << [key, (percent * 100).round(0), (neg_percent * 100).round(0)]

      day += 1.day
    end



    return daily_stats
  end

  #----------------------------------------------------------------------------

end
