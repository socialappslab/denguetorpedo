# -*- encoding : utf-8 -*-


#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding countries..."
puts "\n" * 3

countries = ["Brazil", "Mexico", "Nicaragua"]

puts "-" * 80
puts "[!] Seeding cities..."
puts "\n" * 3

cities = [
  { :name => "Rio de Janeiro", :state => "Rio de Janeiro", :state_code => "RJ", :country_name => "Brazil" },

  { :name => "Tepalcingo", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" },
  { :name => "Cuernavaca", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" },

  { :name => "Managua", :state => "Managua", :state_code => "MN", :country_name => "Nicaragua" }
]
cities.each do |c_hash|
  c = City.find_by_name( c_hash[:name] )
  if c.nil?
    c = City.new
    c.name = c_hash[:name]
    c.state = c_hash[:state]
    c.state_code = c_hash[:state_code]
    c.country = c_hash[:country_name]
    c.time_zone  = "Mexico City"
    c.save!
  end
end


puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

communities = [
  {:name => "Maré",         :city_name => "Rio de Janeiro", :lat => -22.857432, :long => -43.242963},

  {:name => "Tepalcingo",   :city_name => "Tepalcingo", :lat => 18.5957189, :long => -98.8460549 },
  {:name => "Ocachicualli", :city_name => "Cuernavaca", :lat => 18.924799, :long => -99.221359   },

  {:name => "Francisco Meza", :city_name => "Managua", :lat => 12.138632, :long => -86.260808 },
  {:name => "Hialeah",        :city_name => "Managua", :lat => 12.119987, :long => -86.278676 },
  {:name => "Ariel Darce",    :city_name => "Managua", :lat => 12.118762, :long => -86.237639 }
]
communities.each do |c_hash|
  n = Neighborhood.find_by_name( c_hash[:name] )
  if n.nil?
    n                   = Neighborhood.new
    n.name              = c_hash[:name]
    n.latitude          = c_hash[:lat]
    n.longitude         = c_hash[:long]
    n.city_id           = City.find_by_name( c_hash[:city_name] ).id
    n.save!
  end
end


puts "\n" * 3
puts "[ok] Done seeding countries, cities, and neighborhoods..."
puts "-" * 80

#------------------------------------------------------------------------------
