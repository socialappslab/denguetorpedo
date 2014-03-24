# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will place all
# existing users into Mare neighborhood.

namespace :prizes do
  desc "[One-off backfill task] Backfill some prizes with Maré neighborhood"
  task :backfill_some_prizes_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    # Non-community prizes:
    # Bicicleta Aro 26 and Tablet 7'' com wi-fi are general. All else
    # are Mare.
    Prize.where(:community_prize => false).find_each do |prize|
      next if prize.prize_name == "Tablet 7'' com wi-fi"
      next if prize.prize_name == "Bicicleta Aro 26"

      prize.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end

    # Only one community prize is Mare only: Reunião com o representante local da Comlurb
    prize = Prize.find_by_prize_name("Reunião com o representante local da Comlurb")
    prize.update_attribute(:neighborhood_id, mare_neighborhood.id) unless prize.nil?
  end
end
