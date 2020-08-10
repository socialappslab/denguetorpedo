# -*- encoding : utf-8 -*-
# A "Visit" instance is the real-world representation of a physical
# visit to some location. A visit, naturally, has several inspections
# throughout the house and over several dates.
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
  belongs_to :location

  #----------------------------------------------------------------------------
  # Constants

  module Types
    INSPECTION = 0
    FOLLOWUP   = 1
  end

  #----------------------------------------------------------------------------

  def self.questionnaire_for_membership(membership)
    if membership.organization_id == 3
      return VisitQuestionnaire.questions_for_colombia
    elsif membership.organization_id == 5
      return VisitQuestionnaire.questions_for_paraguay
    else
      return VisitQuestionnaire.questions_for_nicaragua
    end
  end

  #----------------------------------------------------------------------------

  def questionnaire_with_answers(membership)
    attr_questions = self.attributes["questions"] || []
    quiz_questions = self.class.questionnaire_for_membership(membership)
    quiz_questions.each do |question|
      matching_q = attr_questions.find {|q| q["code"] == question[:code]}
      question.merge!(:answer => matching_q["answer"]) if matching_q.present?
    end

    return quiz_questions
  end


  #----------------------------------------------------------------------------

  def inspection_types
    types = {Inspection::Types::POSITIVE => false, Inspection::Types::POTENTIAL => false, Inspection::Types::NEGATIVE => false}
    id_grouping = self.inspections.select(:identification_type).group(:identification_type).count
    types[Inspection::Types::POSITIVE]  = (id_grouping[Inspection::Types::POSITIVE] && id_grouping[Inspection::Types::POSITIVE] >= 1)
    types[Inspection::Types::POTENTIAL] = (id_grouping[Inspection::Types::POTENTIAL] && id_grouping[Inspection::Types::POTENTIAL] >= 1)
    types[Inspection::Types::NEGATIVE]  = (!types[Inspection::Types::POSITIVE] && !types[Inspection::Types::POTENTIAL])

    return types
  end

  # This combs through all inspections, returning the most conservative estimate.
  def classification
    hash = self.inspection_types
    return Inspection::Types::POSITIVE  if hash[Inspection::Types::POSITIVE] == true
    return Inspection::Types::POTENTIAL if hash[Inspection::Types::POTENTIAL] == true
    return Inspection::Types::NEGATIVE  if hash[Inspection::Types::NEGATIVE] == true
  end

  def color
    return Inspection.color_for_inspection_status[self.classification]
  end

  def self.find_or_create_visit_for_location_id_and_date(location_id, date)
    return nil if location_id.blank?
    return nil if date.blank?

    v = self.find_by_location_id_and_date(location_id, date)
    if v.blank?
      v             = Visit.new
      v.location_id = location_id
      v.visited_at  = date
      v.save
    end

    return v
  end

  def self.find_by_location_id_and_date(location_id, date)
    visits = Visit.where(:location_id => location_id)
    visits = visits.where(:visited_at => (date.beginning_of_day..date.end_of_day))
    return visits.order("visited_at DESC").first
  end

  #----------------------------------------------------------------------------

  # This calculates the daily percentage of houses that were visited on that day.
  def self.calculate_odds_ratio_for_locations(location_ids, start_time, end_time, scale)
    time_series = Visit.odds_ratio(location_ids, scale)
    time_series = Visit.calculate_statistics_for_odds_ratio(time_series)
    time_series = Visit.filter_time_series_by_range(time_series, start_time, end_time, scale)
    return time_series
  end


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
    # visits       = Visit.select("id, visited_at, location_id").where(:location_id => location_ids).order("visited_at ASC")
    visits       = Visit.where("csv_id IS NOT NULL OR source = ? OR source like ?", "mobile", "%ODK%").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    inspections_by_visit = {}
    # inspections = Inspection.order("position ASC").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
    inspections = Inspection.order("position ASC").where("csv_id IS NOT NULL OR source = ? OR source like ?", "mobile", "%ODK%").where(:visit_id => visits.pluck(:id))
    inspections.map do |ins|
      inspections_by_visit[ins.visit_id] ||= {
        Inspection::Types::POSITIVE  => Set.new,
        Inspection::Types::POTENTIAL => Set.new,
        Inspection::Types::NEGATIVE  => Set.new,
        :protected => Set.new,
        :chemically_treated => Set.new
      }
      inspections_by_visit[ins.visit_id][ins.identification_type].add(ins.id)
      inspections_by_visit[ins.visit_id][:protected].add(ins.id) if ins.protected
      inspections_by_visit[ins.visit_id][:chemically_treated].add(ins.id) if ins.chemically_treated
    end

    # NOTE: We assume here that there is a 1-1 correspondence between visit and day.
    time_series = []
    visits.each do |visit|
      # Identify and find a matching entry for the key we're using. If the key
      # is not present in the time_series, create it.
      # Why Set? Because set is a collection of unordered values with no duplicates.
      # This saves us the time of removing duplicate location ids.
      visit_date = visit.visited_at.strftime("%Y-%m-%d")
      if scale == "yearly"
        visit_date = visit.visited_at.strftime("%Y")
      elsif scale == "monthly"
        visit_date = visit.visited_at.strftime("%Y-%m")
      end

      series = time_series.find {|stat| stat[:date] == visit_date}
      if series.blank?
        series = {:date => visit_date}
        [:positive, :potential, :negative, :protected, :chemically_treated, :total].each do |key|
          series[key] = {:locations => Set.new}
        end
        time_series << series
      end

      # Add to :positive if at least one inspection is positive. Also add to
      # :potential if at least one inspection is potential.
      if visit_counts_by_type = inspections_by_visit[visit.id]
        pos_reports = visit_counts_by_type[Inspection::Types::POSITIVE]
        pot_reports = visit_counts_by_type[Inspection::Types::POTENTIAL]
        series[:positive][:locations].add(visit.location_id)  if pos_reports.size > 0
        series[:potential][:locations].add(visit.location_id) if pot_reports.size > 0

        series[:chemically_treated][:locations].add(visit.location_id) if visit_counts_by_type[:chemically_treated].size > 0
        series[:protected][:locations].add(visit.location_id) if visit_counts_by_type[:protected].size > 0
      end

      # Account for all locations by adding to :total
      series[:total][:locations].add(visit.location_id)

      # Instead of tracking negative location by presence of N and by whether the negative locations are a
      # superset of both positive locations and potential locations (as we were previously doing), we define
      # a negative location as all locations that are neither positive nor potential.
      series[:negative][:locations] = series[:total][:locations] - (series[:positive][:locations] + series[:potential][:locations])
    end

    # Convert set notation to array.
    time_series.each do |ts|
      [:positive, :potential, :negative, :protected, :chemically_treated, :total].each do |key|
        ts[key][:locations] = ts[key][:locations].to_a
      end
    end
    return time_series
  end

  #----------------------------------------------------------------------------

  # This method separates the location_ids into a visit date and, within that, into
  # identification type (positive, potential, negative).
  def self.odds_ratio(location_ids, scale, string_id = "barrel")
    # NOTE: We *cannot* query by start_time here since we would be ignoring the full
    # history of the locations. Instead, we do it at the end.
    # visits       = Visit.select("id, visited_at, location_id").where(:location_id => location_ids).order("visited_at ASC")
    visits       = Visit.where("csv_id IS NOT NULL OR source = ?", "mobile").where(:location_id => location_ids).order("visited_at ASC")
    return [] if visits.blank?

    # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
    inspections_by_visit = {}
    # inspections = Inspection.order("position ASC").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
    inspections = Inspection.order("position ASC").where("csv_id IS NOT NULL OR source = ?", "mobile").where(:visit_id => visits.pluck(:id))
    inspections.map do |ins|
      next unless ins.breeding_site.try(:string_id) == string_id

      inspections_by_visit[ins.visit_id] ||= {
        Inspection::Types::POSITIVE  => Set.new,
        Inspection::Types::POTENTIAL => Set.new,
        Inspection::Types::NEGATIVE  => Set.new,
        :protected => Set.new,
        :chemically_treated => Set.new
      }
      inspections_by_visit[ins.visit_id][ins.identification_type].add(ins.id)

      # This is solely used for Odds-Ratio.
      inspections_by_visit[ins.visit_id][:protected].add(ins.id) if ins.protected
      inspections_by_visit[ins.visit_id][:chemically_treated].add(ins.id) if ins.chemically_treated
    end

    # NOTE: We assume here that there is a 1-1 correspondence between visit and day.
    time_series = []
    visits.each do |visit|
      # Identify and find a matching entry for the key we're using. If the key
      # is not present in the time_series, create it.
      # Why Set? Because set is a collection of unordered values with no duplicates.
      # This saves us the time of removing duplicate location ids.
      visit_date = visit.visited_at.strftime("%Y-%m-%d")
      if scale == "yearly"
        visit_date = visit.visited_at.strftime("%Y")
      elsif scale == "monthly"
        visit_date = visit.visited_at.strftime("%Y-%m")
      end

      series = time_series.find {|stat| stat[:date] == visit_date}
      if series.blank?
        series = {:date => visit_date}
        [:total, :positive_protected, :positive_not_protected, :not_positive_protected, :not_positive_not_protected,
         :positive_chemically_treated, :positive_not_chemically_treated, :not_positive_chemically_treated, :not_positive_not_chemically_treated].each do |key|
          series[key] = {:locations => Set.new}
        end
        time_series << series
      end

      # Add to :positive if at least one inspection is positive. Also add to
      # :potential if at least one inspection is potential.
      if visit_counts_by_type = inspections_by_visit[visit.id]
        # NOTE: Josefina said specifically that if it's potential, you do NOT
        # treat it as positive.
        pos  = (visit_counts_by_type[Inspection::Types::POSITIVE].size > 0)
        prot = visit_counts_by_type[:protected].size > 0
        chem = visit_counts_by_type[:chemically_treated].size > 0


        if pos && prot
          series[:positive_protected][:locations].add(visit.location_id)
        elsif pos && !prot
          series[:positive_not_protected][:locations].add(visit.location_id)
        elsif !pos && prot
          series[:not_positive_protected][:locations].add(visit.location_id)
        elsif !pos && !prot
          series[:not_positive_not_protected][:locations].add(visit.location_id)
        end

        if pos && chem
          series[:positive_chemically_treated][:locations].add(visit.location_id)
        elsif pos && !chem
          series[:positive_not_chemically_treated][:locations].add(visit.location_id)
        elsif !pos && chem
          series[:not_positive_chemically_treated][:locations].add(visit.location_id)
        elsif !pos && !chem
          series[:not_positive_not_chemically_treated][:locations].add(visit.location_id)
        end
      end

      # Account for all locations by adding to :total
      series[:total][:locations].add(visit.location_id)
    end

    # Convert set notation to array.
    time_series.each do |ts|
      [:total, :positive_protected, :positive_not_protected, :not_positive_protected, :not_positive_not_protected,
       :positive_chemically_treated, :positive_not_chemically_treated, :not_positive_chemically_treated, :not_positive_not_chemically_treated].each do |key|
        ts[key][:locations] = ts[key][:locations].to_a
      end
    end

    return time_series
  end


  # #----------------------------------------------------------------------------
  #
  # # This method separates the location_ids into a visit date and, within that, into
  # # identification type (positive, potential, negative).
  # def self.segment_locations_by_date_and_type(location_ids, start_time, end_time, scale)
  #   # NOTE: We *cannot* query by start_time here since we would be ignoring the full
  #   # history of the locations. Instead, we do it at the end.
  #   # visits       = Visit.select("id, visited_at, location_id").where(:location_id => location_ids).order("visited_at ASC")
  #   visits       = Visit.select("id, visited_at, location_id").where("csv_id IS NOT NULL").where(:location_id => location_ids).order("visited_at ASC")
  #   return [] if visits.blank?
  #
  #   # Preload the inspection data so we don't encounter a COUNT(*) N+1 query.
  #   inspections_by_visit = {}
  #   # inspections = Inspection.order("position ASC").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
  #   inspections = Inspection.order("position ASC").where("csv_id IS NOT NULL").where(:visit_id => visits.pluck(:id)).select(:visit_id, :report_id, :identification_type)
  #   inspections.map do |ins|
  #     inspections_by_visit[ins.visit_id] ||= {
  #       Inspection::Types::POSITIVE  => Set.new,
  #       Inspection::Types::POTENTIAL => Set.new,
  #       Inspection::Types::NEGATIVE  => Set.new
  #     }
  #     inspections_by_visit[ins.visit_id][ins.identification_type].add(ins.report_id)
  #   end
  #
  #   # NOTE: We assume here that there is a 1-1 correspondence between visit and day.
  #   time_series = []
  #   visits.each do |visit|
  #     # Identify and find a matching entry for the key we're using. If the key
  #     # is not present in the time_series, create it.
  #     # Why Set? Because set is a collection of unordered values with no duplicates.
  #     # This saves us the time of removing duplicate location ids.
  #     visit_date = (scale == "monthly") ? visit.visited_at.strftime("%Y-%m") : visit.visited_at.strftime("%Y-%m-%d")
  #     series     = time_series.find {|stat| stat[:date] == visit_date}
  #     if series.blank?
  #       series = {:date => visit_date}
  #       [:positive, :potential, :negative, :total].each { |key| series[key] = {:locations => Set.new} }
  #       time_series << series
  #     end
  #
  #     # Account for all locations by adding to :total
  #     series[:total][:locations].add(visit.location_id)
  #
  #     # Add to :positive if at least one inspection is positive. Also add to
  #     # :potential if at least one inspection is potential.
  #     if visit_counts_by_type = inspections_by_visit[visit.id]
  #       pos_reports = visit_counts_by_type[Inspection::Types::POSITIVE]
  #       pot_reports = visit_counts_by_type[Inspection::Types::POTENTIAL]
  #       series[:positive][:locations].add(visit.location_id)  if pos_reports.size > 0
  #       series[:potential][:locations].add(visit.location_id) if pot_reports.size > 0
  #     end
  #
  #     # Instead of tracking negative location by presence of N and by whether the negative locations are a
  #     # superset of both positive locations and potential locations (as we were previously doing), we define
  #     # a negative location as all locations that are neither positive nor potential.
  #     series[:negative][:locations] = series[:total][:locations] - (series[:positive][:locations] + series[:potential][:locations])
  #   end
  #
  #   time_series.each do |ts|
  #     [:positive, :potential, :negative, :total].each do |key|
  #       ts[key][:locations] = ts[key][:locations].to_a
  #     end
  #   end
  #   return time_series
  # end

  #----------------------------------------------------------------------------

  def self.calculate_statistics_for_odds_ratio(time_series)
    time_series.each do |day_statistic|
      [:positive_protected, :positive_not_protected, :not_positive_protected, :not_positive_not_protected,
       :positive_chemically_treated, :positive_not_chemically_treated, :not_positive_chemically_treated, :not_positive_not_chemically_treated].each do |key|
        day_statistic[key][:count] = day_statistic[key][:locations].count
      end
    end

    return time_series
  end


  #----------------------------------------------------------------------------

  def self.calculate_statistics_for_time_series(time_series)
    time_series.each do |day_statistic|
      [:positive, :potential, :negative, :chemically_treated, :protected, :total].each do |key|
        day_statistic[key][:count] = day_statistic[key][:locations].count
      end

      total = day_statistic[:total][:count]
      [:positive, :potential, :chemically_treated, :protected, :negative].each do |key|
        day_statistic[key][:percent] = (total == 0 ? 0 : (day_statistic[key][:count].to_f / total * 100).round(0)  )
      end
    end

    return time_series
  end

  #----------------------------------------------------------------------------

  def self.filter_time_series_by_range(daily_stats, start_time, end_time, scale)
    backup = daily_stats.dup
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

    if daily_stats.length == 0
      daily_stats = backup.dup
      end_time_year  = daily_stats.last[:date].split("-")[0].to_i
      end_time_month = daily_stats.last[:date].split("-")[1].to_i
      end_time_day   = daily_stats.last[:date].split("-")[2].to_i
      start_time_year  = daily_stats.first[:date].split("-")[0].to_i
      start_time_month = daily_stats.first[:date].split("-")[1].to_i
      start_time_day   = daily_stats.first[:date].split("-")[2].to_i
      daily_stats.select! do |stat|
        year  = stat[:date].split("-")[0].to_i
        month = stat[:date].split("-")[1].to_i
        day   = stat[:date].split("-")[2].to_i

        if scale == "daily"
          (year > start_time_year) || (year == start_time_year && month > start_time_month) || (year == start_time_year && month == start_time_month && day >= start_time_day)
        else
          (year > start_time_year) || (year == start_time_year && month >= start_time_month)
        end
      end

      daily_stats.select! do |stat|
        year  = stat[:date].split("-")[0].to_i
        month = stat[:date].split("-")[1].to_i
        day   = stat[:date].split("-")[2].to_i

        if scale == "daily"
          (year < end_time_year) || (year == end_time_year && month < end_time_month) || (year == end_time_year && month == end_time_month && day <= end_time_day)
        else
          (year < end_time_year) || (year == end_time_year && month <= end_time_month)
        end
      end
    end

    return daily_stats
  end

  #----------------------------------------------------------------------------

end
