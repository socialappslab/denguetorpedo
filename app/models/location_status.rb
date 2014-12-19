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
  def self.calculate_time_series_for_locations(locations)
    location_ids    = locations.map(&:id)
    statuses = LocationStatus.where(:location_id => location_ids).order("created_at ASC")
    return [] if statuses.blank?


    # Determine the timeframe.
    start_time  = statuses.first.created_at.beginning_of_day
    end_time    = statuses.last.created_at.end_of_day
    time        = start_time

    # Initialize the memoized hash.
    daily_stats        = []
    memoized_locations = {}

    # Iterate over the timeframe, upating the memoized result each day to reflect
    # the correct state space.
    while time <= end_time
      date_key = time.strftime("%Y-%m-%d")
      stats = statuses.where("DATE(created_at) = ?", date_key)

      # Update the memoized result with new data (or fallback to POTENTIAL)
      stats.each do |location_state|
        memoized_locations[location_state.location_id] = location_state.status || memoized_locations[location_state.location_id] || LocationStatus::Types::POTENTIAL
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

  #-----

  # Adds a calculated location status to location_statuses table based on the following:
  # * If at least one report is positive, then the location is positive,
  # * If no reports are positive, but at least one report is potential, then the
  #   location is potential,
  # * If there are no reports that are positive, or potential, then they are negative
  # * If a location has been negative for 14 days, then it's classified as green.
  # TODO: We can do some optimizations here by comparing current LocationStatus
  # status with the report status...
  # NOTE: We use time input to choose where to calculate the 4 week cutoff for
  # green house.
  def self.calculate_status_using_report_and_times(report, start_time, end_time)

    if report.status == Report::Status::POSITIVE
      return LocationStatus::Types::POSITIVE
    else
      reports = report.location.reports
      count   = reports.find_all {|r| r.status == Report::Status::POSITIVE}.count
      return LocationStatus::Types::POSITIVE if count > 0

      count = reports.find_all {|r| r.status == Report::Status::POTENTIAL}.count
      return LocationStatus::Types::POTENTIAL if count > 0

      # At this point, let's see if this location has been negative for 4 weeks.
      history = LocationStatus.where(:location_id => report.location_id)
      history = history.order("created_at ASC")
      history = history.where(:created_at => (start_time..end_time))

      # Ensure that the first record is in fact 4 weeks ago (at least)
      if history.first && (history.first.created_at <= start_time)

        # We now have a 4 week history. If there is at least one potential, or
        # positive, then this is NOT a clean site (but is negative).
        history = history.pluck(:status)
        if history.include?(LocationStatus::Types::POTENTIAL) || history.include?(LocationStatus::Types::POSITIVE)
          return LocationStatus::Types::NEGATIVE
        else
          return LocationStatus::Types::CLEAN
        end
      else
        return LocationStatus::Types::NEGATIVE
      end

    end
  end

end
