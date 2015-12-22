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
  attr_accessible :location_id, :identification_type, :visited_at, :csv_id, :identified_at, :cleaned_at, :health_report

  #----------------------------------------------------------------------------
  # Validators

  validates :location_id,         :presence => true
  validates :visited_at,          :presence => true

  #----------------------------------------------------------------------------
  # Associations

  has_many :inspections
  has_many :reports, -> {distinct}, :through => :inspections
  belongs_to :spreadsheet, :foreign_key => "csv_id"

  #----------------------------------------------------------------------------
  # Constants

  module Types
    INSPECTION = 0
    FOLLOWUP   = 1
  end

  #----------------------------------------------------------------------------

  # TODO: Deprecate? I don't like this algorithm (and it's outdated) but I haven't had time
  # to check its accuracy.
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

  def inspection_types
    types = {Inspection::Types::POSITIVE => false, Inspection::Types::POTENTIAL => false, Inspection::Types::NEGATIVE => false}
    id_grouping = self.inspections.select(:identification_type).group(:identification_type).count
    types[Inspection::Types::POSITIVE]  = (id_grouping[Inspection::Types::POSITIVE] && id_grouping[Inspection::Types::POSITIVE] >= 1)
    types[Inspection::Types::POTENTIAL] = (id_grouping[Inspection::Types::POTENTIAL] && id_grouping[Inspection::Types::POTENTIAL] >= 1)
    types[Inspection::Types::NEGATIVE]  = (!types[Inspection::Types::POSITIVE] && !types[Inspection::Types::POTENTIAL])

    return types
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
    # visits       = Visit.select("id, visited_at, location_id").where("csv_id IS NOT NULL").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    inspections_by_visit = {}
    inspections = Inspection.order("position ASC").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
    # inspections = Inspection.order("position ASC").where("csv_id IS NOT NULL").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
    inspections.map do |ins|
      inspections_by_visit[ins.visit_id] ||= {
        Inspection::Types::POSITIVE  => Set.new,
        Inspection::Types::POTENTIAL => Set.new,
        Inspection::Types::NEGATIVE  => Set.new
      }
      inspections_by_visit[ins.visit_id][ins.identification_type].add(ins.report_id)
    end

    # NOTE: We assume here that there is a 1-1 correspondence between visit and day.
    time_series = []
    visits.each do |visit|
      # Why Set? Because set is a collection of unordered values with no duplicates.
      # This saves us the time of removing duplicate location ids.
      distribution = {:positive  => {:locations => Set.new}, :potential => {:locations => Set.new}, :negative  => {:locations => Set.new}, :total => {:locations => Set.new}}
      distribution[:total][:locations].add(visit.location_id)

      if visit_counts_by_type = inspections_by_visit[visit.id]
        # At this point, we have a bunch of reports (as keys) and an array of statuses
        # for that report and that specific day, sorted by chronological insertion. We
        # can assume that the last entry is the most recent for that report.
        # The visual explanation here is to treat each report as a row in CSV, and choose
        # the rightmost (elimination) column if it's available.
        pos_reports = visit_counts_by_type[Inspection::Types::POSITIVE]
        pot_reports = visit_counts_by_type[Inspection::Types::POTENTIAL]
        distribution[:positive][:locations].add(visit.location_id)  if pos_reports.size > 0
        distribution[:potential][:locations].add(visit.location_id) if pot_reports.size > 0
      end

      # Instead of tracking negative location by presence of N and by whether the negative locations are a
      # superset of both positive locations and potential locations (as we were previously doing), we define
      # a negative location as all locations that are neither positive nor potential.
      distribution[:negative][:locations] = distribution[:total][:locations] - (distribution[:positive][:locations] + distribution[:potential][:locations])

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
