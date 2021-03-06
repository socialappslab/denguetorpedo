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
    Report.where("created_at < ?", Date.new(2014,12,13)).find_each do |report|
      return if report.location_id.blank?

      # Find today's location_status instance. If it doesn't exist, then
      # create it.
      ls = Visit.where(:location_id => report.location_id)
      ls = ls.where(:created_at => (report.updated_at.beginning_of_day..report.updated_at.end_of_day))
      if ls.blank?
        ls = Visit.new(:location_id => report.location_id)
        ls.created_at = report.created_at
      else
        ls = ls.first
      end

      # TODO: We can do some optimizations here by comparing current Visit
      # status with the report status...
      if report.status == Report::Status::POSITIVE
        ls.status = Visit::Cleaning::POSITIVE
      else
        reports         = report.location.reports
        positive_count  = reports.find_all {|r| r.status == Report::Status::POSITIVE}.count
        potential_count = reports.find_all {|r| r.status == Report::Status::POTENTIAL}.count
        negative_count  = reports.find_all {|r| r.status == Report::Status::NEGATIVE}.count


        if positive_count > 0
          ls.status = Visit::Cleaning::POSITIVE
        elsif potential_count > 0
          ls.status = Visit::Cleaning::POTENTIAL
        else
          # At this point, let's see if this location has been negative for 14 days.
          start = (report.updated_at - 2.weeks).beginning_of_day
          history = Visit.where(:location_id => report.location_id)
          history = history.order("created_at ASC")
          history = history.where(:created_at => (start..report.updated_at.end_of_day))

          # Ensure that the first record is in fact 2 weeks ago (at least)
          if history.first && history.first.created_at <= start
            history = history.pluck(:status)
            if history.include?(Visit::Cleaning::POTENTIAL) || history.include?(Visit::Cleaning::POSITIVE)
              ls.status = Visit::Cleaning::NEGATIVE
            else
              ls.status = Visit::Cleaning::CLEAN
            end
          else
            ls.status = Visit::Cleaning::NEGATIVE
          end

        end
      end


      ls.save
    end
  end


  task :backfill_user_locations => :environment do
    User.find_each do |u|
      loc_ids = u.reports.pluck(:location_id)
      locs    = Location.where(:id => loc_ids)
      locs.each do |loc|
        ul = UserLocation.find_by_user_id_and_location_id(u.id, loc.id)
        if ul.blank?
          UserLocation.create!(:user_id => u.id, :location_id => loc.id, :source => "web", :assigned_at => loc.created_at)
        end
      end
    end
  end

end
