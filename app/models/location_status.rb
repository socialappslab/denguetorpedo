# NOTE: The associated Visit table stores a *daily* snapshot
# of the location's status. This means that if several reports are created in
# a day, then we will simply update the existing Visit entry.
# This has two benefits:
# a) statistics are *much* faster to calculate
# b) there is no need for real-time location statuses.I went with real-time series before this,
#    and it was a hassle to calculate daily trends (which is all what people care about).

# A Visit is the correct real-world representation instead of Visit, as
# we're tracking the health status of a location at a given time. This
# "track" can be roughly thought of as a visit to that location.
#
# Armed with this thought process, it now becomes obvious to append
# more properties to this model. For instance,
# * dengue cases,
# * chik cases,
# * identification type (positive, potential, or negative/clean)
# * time of identification
# * time of cleaning (if the elimination was performed).
#
# Note that this model limits the number of actions a user can do: either
# identify (and do nothing), or identify and clean the whole place.
class Visit < ActiveRecord::Base
  attr_accessible :location_id, :status, :health_report

  #----------------------------------------------------------------------------
  # Validators

  validates :location_id,         :presence => true
  validates :identification_type, :presence => true
  validates :identified_at,       :presence => true

  #----------------------------------------------------------------------------
  # Constants

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

  # This is a convenience method that uses calculate_time_series_for_locations_in_timeframe
  # under the hood.
  def self.calculate_time_series_for_locations(locations)
    location_ids    = locations.map(&:id)
    statuses = Visit.where(:location_id => location_ids).order("created_at ASC")
    return [] if statuses.blank?

    # Determine the timeframe.
    start_time  = statuses.first.created_at.beginning_of_day
    end_time    = statuses.last.created_at.end_of_day
    self.calculate_time_series_for_locations_in_timeframe(locations, start_time, end_time)
  end

  # In order to calculate time series for locations, we need to realize that
  # location statuses exhibit "gaps" in reported status of a location. This means
  # that there is no guarantee we have a record of the location status on any
  # given day. Instead, we have to calculate it based on *last known row entry* (assume
  # POTENTIAL if no entry). This is what is known as the "Gaps and Islands" problem:
  # https://www.simple-talk.com/sql/t-sql-programming/the-sql-of-gaps-and-islands-in-sequences/
  # The islands are singular row entries of the location, and the gaps are all the days
  # that we don't have an entry for that location.
  #
  # There are several ways to try to solve this problem. One is to perform SQL for
  # each day by ordering in reverse chronological order, and looking at all days in the
  # past, and then grouping by location. This is problematic since you have to ensure
  # that each location is counted only once. I haven't found a clean way for doig this.
  #
  # An alternative way is to memoize the location statuses, and calculate percentages
  # from this memoized result, making sure to update this memoized result after each
  # day iteration. In other words, we essentially keep track of all locations, and update
  # each location with new metrics as we get more information.
  # NOTE: Keep in mind that we can't just initialize the memoized variable with
  # all locations as not all locations existed for all time. Otherwise, we may
  # skew the actual statistics.
  def self.calculate_time_series_for_locations_in_timeframe(locations, start_time, end_time)
    location_ids    = locations.map(&:id)
    statuses = Visit.where(:location_id => location_ids).order("created_at ASC")
    return [] if statuses.blank?

    # NOTE: To avoid overloading the server, we have to limit the timeframe to 6 months.
    if (end_time - start_time).abs > 6.months
      start_time = end_time - 6.months
    end

    # Initialize the memoized hash.
    time               = start_time
    daily_stats        = []
    memoized_locations = {}

    # Iterate over the timeframe, upating the memoized result each day to reflect
    # the correct state space.
    while time <= end_time
      date_key = time.strftime("%Y-%m-%d")
      stats = statuses.where("DATE(created_at) = ?", date_key)

      # Update the memoized result with new data (or fallback to POTENTIAL)
      stats.each do |location_state|
        memoized_locations[location_state.location_id] = location_state.status || memoized_locations[location_state.location_id] || Visit::Types::POTENTIAL
      end

      # Calculate the count and percentages of the latest memoized result.
      positive_count  = memoized_locations.find_all {|loc_id, status| status == Types::POSITIVE}.count
      potential_count = memoized_locations.find_all {|loc_id, status| status == Types::POTENTIAL}.count
      negative_count  = memoized_locations.find_all {|loc_id, status| status == Types::NEGATIVE}.count
      clean_count     = memoized_locations.find_all {|loc_id, status| status == Types::CLEAN}.count
      total_count     = positive_count + potential_count + negative_count + clean_count

      pos_percent   = total_count == 0 ? 0 : (positive_count).to_f  / total_count
      pot_percent   = total_count == 0 ? 0 : (potential_count).to_f / total_count
      neg_percent   = total_count == 0 ? 0 : (negative_count).to_f  / total_count
      clean_percent = total_count == 0 ? 0 : (clean_count).to_f     / total_count

      hash = {
        :date => date_key,
        :positive  => {:count => positive_count,  :percent => (pos_percent * 100).round(0)},
        :potential => {:count => potential_count, :percent => (pot_percent * 100).round(0)},
        :negative  => {:count => negative_count,  :percent => (neg_percent * 100).round(0)},
        :clean     => {:count => clean_count,     :percent => (clean_percent * 100).round(0)}
      }
      daily_stats << hash
      time += 1.day
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------


end
