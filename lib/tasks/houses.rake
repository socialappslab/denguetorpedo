# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will populate
# all existing houses with the Mare neighborhood.

namespace :houses do
  desc "[One-off backfill task] Backfill houses with Maré neighborhood"
  task :backfill_houses_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    House.find_each do |h|
      next if h.neighborhood_id.present?
      h.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end
  end
end
