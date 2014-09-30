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
end
