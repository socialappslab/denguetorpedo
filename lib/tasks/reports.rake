# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will populate
# all existing houses with the Mare neighborhood.

namespace :reports do
  desc "[One-off backfill task] Backfill reports with Maré neighborhood"
  task :backfill_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    Report.find_each do |r|
      next if r.neighborhood_id.present?
      r.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end
  end
end
