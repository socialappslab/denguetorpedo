# NOTE: The associated Visit table's granularity is down to the *day*, meaning
# that if several reports are created in a day, then we will simply update the
# existing Visit entry.
# This has two benefits:
# a) statistics are *much* faster to calculate
# b) there is no need for real-time visits.I went with real-time series before this,
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
# * time of visit
# * type of visit
#
# Note that this model limits the number of actions a user can do: either
# identify (and do nothing), or identify and clean the whole place.
#
# For our purposes, there are only *two* visits: an identification visit,
# and a followup visit. The act of identifying and eliminating breeding sites
# falls into one of the two classes.
class Visit < ActiveRecord::Base
  attr_accessible :location_id, :identification_type, :identified_at, :cleaned_at, :health_report

  #----------------------------------------------------------------------------
  # Validators

  validates :location_id,         :presence => true
  validates :identification_type, :presence => true
  validates :visit_type,          :presence => true
  validates :visited_at,          :presence => true

  #----------------------------------------------------------------------------
  # Constants

  # The status of a location defines whether it's positive, potential, negative
  # or clean. The first three are defined by the associated reports at that
  # location, and the last one is separately set in the database. See the
  # 'status' instance method.
  module Cleaning
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
    CLEAN     = 3
  end

  module Types
    INSPECTION = 0
    FOLLOWUP   = 1
  end

  #----------------------------------------------------------------------------

  # The status of a visit depends on its identification_type, identified_at date
  # and cleaned_at date as follows:
  # * If cleaned_at is nil, then that means the site was identified but not
  #   cleaned since last reported report (note: this does not mean it was never
  #   cleaned). We rely on identification_type to define the status.
  # * If cleaned_at is present, then we compare it to the date of identified_at.
  #   If they match, then we still report that location as whatever identification_type
  #   has it set. If cleaned_at and identified_at dates do NOT match, then we
  #   treat this location as cleaned.
  # TODO: We don't implement CLEAN status for now since it requires heavy SQL
  # queries into the history of Visits.
  # def state
  #   if self.cleaned_at.blank?
  #     return self.identification_type
  #   elsif self.cleaned_at.beginning_of_day == self.identified_at.beginning_of_day
  #     return self.identification_type
  #   else
  #     return Visit::Cleaning::NEGATIVE
  #   end
  # end

  # We set the identification type to be the *worst* found type, meaning that
  # if the report is positive, we set the identification_type to positive. If
  # the report is positive and the identification_type is already positive, then
  # we keep it positive.
  def calculate_identification_type_for_report(report)
    # Immediately return if the status of this report is POSITIVE.
    return Report::Status::POSITIVE if report.status == Report::Status::POSITIVE

    # At this point, the status of a report is either potential or negative.
    # We must result to calculating the status of other reports before knowing
    # what the identification_type of this visit should be.
    reports          = report.location.reports
    positive_report  = reports.find {|r| r.status == Report::Status::POSITIVE  }
    potential_report = reports.find {|r| r.status == Report::Status::POTENTIAL }

    return Report::Status::POSITIVE  if positive_report.present?
    return Report::Status::POTENTIAL if potential_report.present?

    # At this point, there are no positive or potential reports. The identification_type
    # of this location depends purely on this report...
    return report.status
  end

  # This is a convenience method that uses calculate_time_series_for_locations_in_timeframe
  # under the hood.
  def self.calculate_time_series_for_locations(locations)
    location_ids = locations.map(&:id)
    visits  = Visit.where(:location_id => location_ids).order("identified_at ASC")
    return [] if visits.blank?

    # Determine the timeframe.
    start_time = visits.first.identified_at.beginning_of_day
    end_time   = visits.last.identified_at.end_of_day
    self.calculate_time_series_for_locations_in_timeframe(locations, start_time, end_time)
  end

  # In order to calculate time series for locations, we need to realize that
  # location visits exhibit "gaps" in reported status of a location. This means
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
  # An alternative way is to memoize the location visits, and calculate percentages
  # from this memoized result, making sure to update this memoized result after each
  # day iteration. In other words, we essentially keep track of all locations, and update
  # each location with new metrics as we get more information.
  # NOTE: Keep in mind that we can't just initialize the memoized variable with
  # all locations as not all locations existed for all time. Otherwise, we may
  # skew the actual statistics.
  def self.calculate_time_series_for_locations_in_timeframe(locations, start_time, end_time)
    location_ids = locations.map(&:id)
    visits       = Visit.where(:location_id => location_ids).order("identified_at ASC")
    return [] if visits.blank?

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
      stats = visits.where("DATE(identified_at) = ?", date_key)

      # Update the memoized result with new data (or fallback to POTENTIAL)
      stats.each do |v|
        memoized_locations[v.location_id] = v.state || memoized_locations[v.location_id]
      end

      # Calculate the count and percentages of the latest memoized result.
      positive_count  = memoized_locations.find_all {|loc_id, status| status == Report::Status::POSITIVE}.count
      potential_count = memoized_locations.find_all {|loc_id, status| status == Report::Status::POTENTIAL}.count
      negative_count  = memoized_locations.find_all {|loc_id, status| status == Report::Status::NEGATIVE}.count
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
