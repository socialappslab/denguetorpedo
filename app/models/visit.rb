# -*- encoding : utf-8 -*-
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
require "set"

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

  def self.find_or_create_visit_for_location_id_and_date(location_id, date)
    return nil if location_id.blank?
    return nil if date.blank?

    v = Visit.where(:location_id => location_id)
    v = v.where(:visited_at => (date.beginning_of_day..date.end_of_day))
    v = v.order("visited_at DESC").first
    if v.blank?
      v             = Visit.new
      v.location_id = location_id
      v.visited_at  = date
      v.save
    end

    return v
  end

  #----------------------------------------------------------------------------

  # This calculates the daily percentage of houses that were visited on that day.
  def self.calculate_time_series_for_locations(location_ids, start_time, end_time, scale)
    time_series = Visit.segment_locations_by_date_and_type(location_ids, start_time, end_time, scale)
    time_series = Visit.calculate_statistics_for_time_series(time_series)
    time_series = Visit.filter_time_series_by_range(time_series, start_time, end_time, scale)
    return time_series
  end

  #----------------------------------------------------------------------------

  # This method separates the location_ids into a visit date and, within that, into
  # identification type (positive, potential, negative).
  def self.segment_locations_by_date_and_type(location_ids, start_time, end_time, scale)
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    visits       = Visit.select("id, visited_at, location_id").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    # NOTE: I've considered using SQL joins here, but:
    # a) inner joining inspections on visits leads to problems when calculating
    #    identification type since a visit has many inspections,
    # b) inner joining visits on inspections leads to problems with accounting
    #    for visits with no inspections (e.g. those that are N on CSV forms)
    inspections_hash = Inspection.where(:visit_id => visits.pluck(:id)).select([:visit_id, :identification_type]).group(:visit_id, :identification_type).count(:identification_type)

    # NOTE: We assume here that there is a 1-1 correspondence between visit and day.
    time_series = []
    visits.each do |visit|
      # Calculate the number of positive inspections for this visit, and
      # calculate number of potential inspections for this visit.
      # If there are no inspections that match this visit, then we will bypass it completely.
      visit_counts_by_type = inspections_hash.find_all {|k, v| k[0] == visit.id}
      next if visit_counts_by_type.blank?

      # Why Set? Because set is a collection of unordered values with no duplicates.
      # This saves us the time of removing duplicate location ids.
      distribution = {:positive  => {:locations => Set.new}, :potential => {:locations => Set.new}, :negative  => {:locations => Set.new}, :total => {:locations => Set.new}}

      # Calculate the number of positive and potential instances for this particular visit.
      # All other instances are negative.
      pos_count    = visit_counts_by_type.find {|k,v| k[1] == Inspection::Types::POSITIVE}
      pos_count    = pos_count[1] if pos_count
      pot_count    = visit_counts_by_type.find {|k,v| k[1] == Inspection::Types::POTENTIAL}
      pot_count    = pot_count[1] if pot_count

      distribution[:positive][:locations].add(visit.location_id) if pos_count && pos_count > 0
      distribution[:potential][:locations].add(visit.location_id) if pot_count && pot_count > 0
      distribution[:negative][:locations].add(visit.location_id) if pos_count.blank? && pot_count.blank?
      distribution[:total][:locations].add(visit.location_id)

      # Identify and find a matching entry for the key we're using. If the key
      # is not present in the time_series, create it.
      visit_date = (scale == "monthly") ? visit.visited_at.strftime("%Y-%m") : visit.visited_at.strftime("%Y-%m-%d")
      series     = time_series.find {|stat| stat[:date] == visit_date}
      if series.blank?
        series = {:date => visit_date}
        [:positive, :potential, :negative, :total].each do |key|
          series[key] = {:locations => distribution[key][:locations]}
        end

        time_series << series
      else
        [:positive, :potential, :negative, :total].each do |key|
          series[key][:locations].merge(distribution[key][:locations])
        end
      end
    end

    # Before we return, let's convert the sets to array.
    time_series.each do |ts|
      [:positive, :potential, :negative, :total].each do |key|
        ts[key][:locations] = ts[key][:locations].to_a
      end
    end

    return time_series
  end

  #----------------------------------------------------------------------------

  def self.calculate_statistics_for_time_series(time_series)
    time_series.each do |day_statistic|
      [:positive, :potential, :negative, :total].each do |key|
        day_statistic[key][:count] = day_statistic[key][:locations].count
      end

      total = day_statistic[:total][:count]
      [:positive, :potential, :negative].each do |key|
        day_statistic[key][:percent] = (total == 0 ? 0 : (day_statistic[key][:count].to_f / total * 100).round(0)  )
      end
    end

    return time_series
  end

  #----------------------------------------------------------------------------

  def self.filter_time_series_by_range(daily_stats, start_time, end_time, scale)
    if start_time.present?
      daily_stats.select! do |stat|
        year  = stat[:date].split("-")[0].to_i
        month = stat[:date].split("-")[1].to_i
        day   = stat[:date].split("-")[2].to_i

        if scale == "daily"
          (year > start_time.year) || (year == start_time.year && month > start_time.month) || (year == start_time.year && month == start_time.month && day >= start_time.day)
        else
          (year > start_time.year) || (year == start_time.year && month >= start_time.month)
        end
      end
    end

    if end_time.present?
      daily_stats.select! do |stat|
        year  = stat[:date].split("-")[0].to_i
        month = stat[:date].split("-")[1].to_i
        day   = stat[:date].split("-")[2].to_i

        if scale == "daily"
          (year < end_time.year) || (year == end_time.year && month < end_time.month) || (year == end_time.year && month == end_time.month && day <= end_time.day)
        else
          (year < end_time.year) || (year == end_time.year && month <= end_time.month)
        end
      end
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------

end
