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
  def calculate_identification_type_from_status_and_reports(status, reports)
    # Immediately return if the status of this report is POSITIVE.
    return Report::Status::POSITIVE if status == Report::Status::POSITIVE

    # At this point, the status of a report is either potential or negative.
    # We must result to calculating the status of other reports before knowing
    # what the identification_type of this visit should be.
    positive_report  = reports.find {|r| r.status == Report::Status::POSITIVE  }
    potential_report = reports.find {|r| r.status == Report::Status::POTENTIAL }

    return Report::Status::POSITIVE  if positive_report.present?
    return Report::Status::POTENTIAL if potential_report.present?

    # At this point, there are no positive or potential reports. The identification_type
    # of this location depends purely on this report...
    return status
  end

  #----------------------------------------------------------------------------

  # This calculates the daily percentage of houses that were visited on that day.
  def self.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations, start_time = nil, visit_types = nil)
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    location_ids = locations.map(&:id)
    visits       = Visit.where(:location_id => location_ids).order("DATE(visited_at) ASC")
    visits       = visits.select([:visited_at, :identification_type, :visit_type])
    return [] if visits.blank?

    daily_stats = []
    visits_by_date_and_type = visits.group("DATE(visited_at)", :identification_type, :visit_type).count
    visits_by_date_and_type.each do |grouping, count|
      visited_at_date     = grouping[0].to_s
      identification_type = grouping[1].to_i
      visit_type          = grouping[2].to_i

      day_statistic = daily_stats.find {|stat| stat[:date] == visited_at_date}
      if day_statistic.blank?
        day_statistic = {
          :date       => visited_at_date,
          :matching_visit_type => false,
          :positive   => {:count => 0, :percent => 0},
          :potential  => {:count => 0, :percent => 0},
          :negative   => {:count => 0, :percent => 0},
          :total      => {:count => 0}
        }

        daily_stats << day_statistic
      end

      # NOTE: To include only the visit types that we're matching against, we're
      # going to simply compare all visit types for this date, and if at least
      # one visit type matches the one we want, then we'll set the value to true.
      matching_visit_type = visit_types.blank? || visit_types.include?(visit_type)
      day_statistic[:matching_visit_type] = true if matching_visit_type == true

      # Define the relative count for each identification type (and total, as well)
      key = Report.statuses_as_symbols[identification_type]
      day_statistic[key][:count]    = count
      day_statistic[:total][:count] += count

      # NOTE: We're not adding the hash here because there's a chance we simply
      # modified an existing element. We're going to search for it again.
      index              = daily_stats.find_index {|stat| stat[:date] == visited_at_date}
      daily_stats[index] = day_statistic
    end

    # Now, let's iterate over daily_stats, calculating percentage.
    # Finally, let's include only those visit types that match the visit type.
    # Now that the full history is captured, let's filter starting from the start_time
    daily_stats = Visit.calculate_percentages_for_time_series(daily_stats)
    daily_stats = daily_stats.find_all {|ds| ds[:matching_visit_type] == true}
    daily_stats = Visit.filter_time_series_from_date(daily_stats, start_time)

    return daily_stats
  end

  #----------------------------------------------------------------------------

  def self.calculate_cumulative_time_series_for_locations_start_time_and_visit_types(locations, start_time = nil, visit_types = nil)
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    location_ids = locations.map(&:id)
    visits       = Visit.where(:location_id => location_ids).order("DATE(visited_at) ASC")
    visits       = visits.select([:visited_at, :identification_type, :visit_type])
    return [] if visits.blank?

    daily_stats = []
    visits_by_date_and_type = visits.group("DATE(visited_at)", :identification_type, :visit_type).count
    visits_by_date_and_type.each do |grouping, count|
      visited_at_date     = grouping[0].to_s
      identification_type = grouping[1].to_i
      visit_type          = grouping[2].to_i

      day_statistic = daily_stats.find {|stat| stat[:date] == visited_at_date}
      if day_statistic.blank?

        if daily_stats.length == 0
          positive_count  = 0
          potential_count = 0
          negative_count  = 0
        else
          positive_count  = daily_stats[-1][:positive][:count]
          potential_count = daily_stats[-1][:potential][:count]
          negative_count  = daily_stats[-1][:negative][:count]
        end

        day_statistic = {
          :date       => visited_at_date,
          :matching_visit_type => false,
          :positive   => {:count => positive_count, :percent => 0},
          :potential  => {:count => potential_count, :percent => 0},
          :negative   => {:count => negative_count, :percent => 0},
          :total      => {:count => positive_count + potential_count + negative_count}
        }

        daily_stats << day_statistic
      else
        day_statistic[:positive][:count]  = daily_stats[-1][:positive][:count]
        day_statistic[:potential][:count] = daily_stats[-1][:potential][:count]
        day_statistic[:negative][:count]  = daily_stats[-1][:negative][:count]
        day_statistic[:total][:count]     = daily_stats[-1][:total][:count]
      end

      # NOTE: To include only the visit types that we're matching against, we're
      # going to simply compare all visit types for this date, and if at least
      # one visit type matches the one we want, then we'll set the value to true.
      matching_visit_type = visit_types.blank? || visit_types.include?(visit_type)
      day_statistic[:matching_visit_type] = true if matching_visit_type == true

      key = Report.statuses_as_symbols[identification_type]
      day_statistic[key][:count]    += count
      day_statistic[:total][:count] += count

      # NOTE: We're not adding the hash here because there's a chance we simply
      # modified an existing element. We're going to search for it again.
      index = daily_stats.find_index {|stat| stat[:date] == visited_at_date}
      daily_stats[index] = day_statistic
    end

    # Now, let's iterate over daily_stats, calculating percentage.
    # Finally, let's include only those visit types that match the visit type.
    # Now that the full history is captured, let's filter starting from the start_time
    daily_stats = Visit.calculate_percentages_for_time_series(daily_stats)
    daily_stats = daily_stats.find_all {|ds| ds[:matching_visit_type] == true}
    daily_stats = Visit.filter_time_series_from_date(daily_stats, start_time)

    return daily_stats
  end

  #----------------------------------------------------------------------------

  def self.calculate_percentages_for_time_series(daily_stats)
    daily_stats.each_with_index do |day_statistic, index|
      positive_count  = day_statistic[:positive][:count]
      potential_count = day_statistic[:potential][:count]
      negative_count  = day_statistic[:negative][:count]
      total           = day_statistic[:total][:count]

      day_statistic[:positive][:percent]  = (total == 0 ? 0 : (positive_count.to_f / total * 100).round(0)  )
      day_statistic[:potential][:percent] = (total == 0 ? 0 : (potential_count.to_f / total * 100).round(0) )
      day_statistic[:negative][:percent]  = (total == 0 ? 0 : (negative_count.to_f / total * 100).round(0)  )

      daily_stats[index] = day_statistic
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------

  def self.filter_time_series_from_date(daily_stats, start_time)
    if start_time.present?
      parsed_start_time = start_time.strftime("%Y-%m-%d")
      first_index = daily_stats.find_index { |day_stat| Time.parse(day_stat[:date]) >= Time.parse(parsed_start_time) }
      daily_stats = daily_stats[first_index..-1] if first_index.present?
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------

end
