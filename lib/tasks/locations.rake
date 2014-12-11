# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will populate
# all existing locations with the Mare neighborhood.
# DO NOT run this without permission from @dman7.

namespace :locations do
  desc "[One-off backfill task] Backfill locations with Maré neighborhood"
  task :backfill_locations_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    Location.find_each do |loc|
      next if loc.neighborhood_id.present?
      loc.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end
  end

  task :backfill_statuses => :environment do
    Report.find_each do |report|
      next if report.location_id.blank?

      ls = LocationStatus.where(:location_id => report.location_id)
      ls = ls.where(:created_at => (report.created_at.beginning_of_day..report.created_at.end_of_day))
      if ls.blank?
        ls            = LocationStatus.new(:location_id => report.location_id)
        ls.created_at = report.created_at
      else
        ls = ls.first
      end

      reports         = report.location.reports
      positive_count  = reports.find_all {|r| r.status == Report::Status::POSITIVE}.count
      negative_count  = reports.find_all {|r| r.status == Report::Status::NEGATIVE}.count

      if positive_count > 0
        ls.status = LocationStatus::Types::POSITIVE
      elsif negative_count > 0
        ls.status = LocationStatus::Types::NEGATIVE
      else
        ls.status = LocationStatus::Types::POTENTIAL
      end

      ls.save
    end
  end
end
