# A "Visit" instance is the real-world representation of a physical
# visit to some location. A visit, naturally, has several inspections
# throughout the house and over several dates. Each inspection creates
# a report on the site.
#
# The following properties are defined on the model:
# * dengue cases,
# * chik cases,
# * identification type (positive, potential, or negative/clean)
# * time of visit
# * type of visit
class Visit < ActiveRecord::Base
  attr_accessible :location_id, :identification_type, :identified_at, :cleaned_at, :health_report

  #----------------------------------------------------------------------------
  # Validators

  validates :location_id,         :presence => true
  validates :visited_at,          :presence => true

  #----------------------------------------------------------------------------
  # Associations

  has_many :inspections
  has_many :reports, :through => :inspections

  #----------------------------------------------------------------------------
  # Constants

  module Types
    INSPECTION = 0
    FOLLOWUP   = 1
  end

  def visit_type
    return Types::FOLLOWUP if self.parent_visit_id.present?
    return Types::INSPECTION
  end

  #----------------------------------------------------------------------------

  def identification_type
    id_grouping = self.inspections.select(:identification_type).group(:identification_type).count
    if id_grouping[Inspection::Types::POSITIVE] && id_grouping[Inspection::Types::POSITIVE] >= 1
      return Inspection::Types::POSITIVE
    elsif id_grouping[Inspection::Types::POTENTIAL] && id_grouping[Inspection::Types::POTENTIAL] >= 1
      return Inspection::Types::POTENTIAL
    else
      return Inspection::Types::NEGATIVE
    end
  end

  #----------------------------------------------------------------------------

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
  def self.calculate_daily_time_series_for_locations_start_time_and_visit_types(location_ids, start_time = nil, visit_types = nil)
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    visits       = Visit.select("id, visited_at, location_id, parent_visit_id").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    # NOTE: I've considered using SQL joins here, but:
    # a) inner joining inspections on visits leads to problems when calculating
    #    identification type since a visit has many inspections,
    # b) inner joining visits on inspections leads to problems with accounting
    #    for visits with no inspections (e.g. those that are N on CSV forms)
    visit_ids = visits.pluck(:id)
    visit_identification_hash = Inspection.where(:visit_id => visit_ids).select([:visit_id, :identification_type]).group(:visit_id, :identification_type).count(:identification_type)

    daily_stats = []
    visits.each do |visit|
      visited_at_date     = visit.visited_at.strftime("%Y-%m-%d")
      visit_type          = visit.visit_type

      day_statistic = daily_stats.find {|stat| stat[:date] == visited_at_date}
      if day_statistic.blank?
        day_statistic = {
          :date       => visited_at_date,
          :positive   => {:count => 0, :percent => 0},
          :potential  => {:count => 0, :percent => 0},
          :negative   => {:count => 0, :percent => 0},
          :total      => {:count => 0}
        }

        daily_stats << day_statistic
      end

      if visit_types.blank? || visit_types.include?(visit_type)
        # The daily metric calculates number of visited houses
        # that had at least one potential and/or at least one positive
        # site. This means we need to ask if the house had a potential site,
        # and if the house had a positive site.
        # We do this by checking if there is an entry in the visit_identifaction_hash
        # by narrowing the array size as fast as possible.
        visit_counts = visit_identification_hash.find_all {|k, v| k[0] == visit.id}
        pot_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POTENTIAL}
        pot_count    = pot_count[1] if pot_count
        pos_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POSITIVE}
        pos_count    = pos_count[1] if pos_count

        day_statistic[:potential][:count] += 1 if pot_count && pot_count > 0
        day_statistic[:positive][:count]  += 1 if pos_count && pos_count > 0
        day_statistic[:negative][:count]  += 1 if pot_count.blank? && pos_count.blank?
        day_statistic[:total][:count]     += 1
      end

      # NOTE: We're not adding the hash here because there's a chance we simply
      # modified an existing element. We're going to search for it again.
      index              = daily_stats.find_index {|stat| stat[:date] == visited_at_date}
      daily_stats[index] = day_statistic
    end

    # Now, let's iterate over daily_stats, calculating percentage.
    # Finally, let's include only those visit types that match the visit type.
    # Now that the full history is captured, let's filter starting from the start_time
    daily_stats = Visit.calculate_percentages_for_time_series(daily_stats)
    daily_stats = Visit.filter_time_series_from_date(daily_stats, start_time)

    return daily_stats
  end

  #----------------------------------------------------------------------------

  def self.calculate_cumulative_time_series_for_locations_and_start_time(location_ids, start_time = nil)
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    visits       = Visit.select("id, visited_at, location_id, parent_visit_id").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    # NOTE: I've considered using SQL joins here, but:
    # a) inner joining inspections on visits leads to problems when calculating
    #    identification type since a visit has many inspections,
    # b) inner joining visits on inspections leads to problems with accounting
    #    for visits with no inspections (e.g. those that are N on CSV forms)
    visit_ids = visits.pluck(:id)
    visit_identification_hash = Inspection.where(:visit_id => visit_ids).select([:visit_id, :identification_type]).group(:visit_id, :identification_type).count(:identification_type)

    # We're going to memoize the last known status of each location in order to
    # correctly update the total positive/potential/negative count.
    memoized_locations = []

    # Limit the location ids to those that we have visits for (the method argument
    # refers to all locations in a neighborhood).
    location_ids = visits.pluck(:location_id).uniq

    daily_stats = []
    visits.each do |visit|
      visited_at_date     = visit.visited_at.strftime("%Y-%m-%d")
      visit_type          = visit.visit_type
      location_id         = visit.location_id

      day_statistic = daily_stats.find {|stat| stat[:date] == visited_at_date}
      if day_statistic.blank?
        day_statistic = {
          :date       => visited_at_date,
          :positive   => {:count => 0, :percent => 0},
          :potential  => {:count => 0, :percent => 0},
          :negative   => {:count => 0, :percent => 0},
          :total      => {:count => location_ids.count}
        }
        daily_stats << day_statistic
      end

      # Calculate the status type of this location.
      # The cumulative metric calculates number of visited houses
      # that had at least one potential and/or at least one positive
      # site. This means we need to ask if the house had a potential site,
      # and if the house had a positive site.
      # We do this by checking if there is an entry in the visit_identifaction_hash
      # by narrowing the array size as fast as possible.
      # If there is an entry in both, then we set the identification type to both
      # statuses.
      visit_counts = visit_identification_hash.find_all {|k, v| k[0] == visit.id}
      pot_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POTENTIAL}
      pos_count    = visit_counts.find {|k,v| k[1] == Inspection::Types::POSITIVE}

      if pos_count && pos_count[1] > 0 && pot_count && pot_count[1] > 0
        identification_type = [Report::Status::POSITIVE, Report::Status::POTENTIAL]
      elsif pos_count && pos_count[1] > 0
        identification_type = [Report::Status::POSITIVE]
      elsif pot_count && pot_count[1] > 0
        identification_type = [Report::Status::POTENTIAL]
      else
        identification_type = [Report::Status::NEGATIVE]
      end

      # Memoize the location with the latest status.
      location = memoized_locations.find {|loc| loc[:id] == location_id}
      if location.blank?
        location = {:id => location_id}
        memoized_locations << location
      end
      location[:status] = identification_type
      index = memoized_locations.find_index {|stat| stat[:id] == location_id}
      memoized_locations[index] = location

      # Use the updated memoized_locations to set the distribution of positive,
      # potential and negative statuses. Note that each location can potentially
      # have several statuses (e.g. positive and potential).
      Report.statuses_as_symbols.each do |key, value|
        key_count = memoized_locations.find_all {|loc| loc[:status].include?(key) }.count
        day_statistic[value][:count] = key_count
      end


      # NOTE: We're not adding the hash here because there's a chance we simply
      # modified an existing element. We're going to search for it again.
      index              = daily_stats.find_index {|stat| stat[:date] == visited_at_date}
      daily_stats[index] = day_statistic
    end

    # Now, let's iterate over daily_stats, calculating percentage.
    # Finally, let's include only those visit types that match the visit type.
    # Now that the full history is captured, let's filter starting from the start_time
    daily_stats = Visit.calculate_percentages_for_time_series(daily_stats)
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

      if first_index.present?
        daily_stats = daily_stats[first_index..-1]
      else
        daily_stats = []
      end
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------

end
