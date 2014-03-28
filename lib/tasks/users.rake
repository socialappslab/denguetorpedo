# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will place all
# existing users into Mare neighborhood.

namespace :users do
  desc "[One-off backfill task] Backfill users with Maré neighborhood"
  task :backfill_users_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    User.find_each do |user|
      user.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end
  end
end
