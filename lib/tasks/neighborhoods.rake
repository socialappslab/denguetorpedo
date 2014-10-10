# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will populate
# all existing neighborhoods with city data.

namespace :neighborhoods do
  desc "[Backfill task] Backfill neighborhoods with city data"
  task :backfill_with_cities => :environment do
    communities = [
      {:name => "Maré",         :city_name => "Rio de Janeiro"},
      {:name => "Tepalcingo",   :city_name => "Tepalcingo"},
      {:name => "Ocachicualli", :city_name => "Cuernavaca"}
    ]
    communities.each do |c_hash|
      n          = Neighborhood.find_by_name( c_hash[:name] )
      n.city_id  = City.find_by_name( c_hash[:city_name] ).id
      n.save!
    end
  end

  desc "Add latitude/longitude to neighborhoods"
  task :add_coordinates => :environment do
    communities = [
      {:name => "Maré",         :lat => -22.857432, :long => -43.242963  },
      {:name => "Tepalcingo",   :lat => 18.5957189, :long => -98.8460549 },
      {:name => "Ocachicualli", :lat => 18.924799, :long => -99.221359   },

      {:name => "Francisco Meza", :lat => 12.138632, :long => -86.260808 },
      {:name => "Hialeah",        :lat => 12.119987, :long => -86.278676 },
      {:name => "Ariel Darce",    :lat => 12.118762, :long => -86.237639 }
    ]
    communities.each do |c|
      n = Neighborhood.find_by_name(c[:name])
      n.latitude  = c[:lat]
      n.longitude = c[:long]
      n.save!
    end
  end
end
