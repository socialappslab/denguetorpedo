# encoding: UTF-8

require "#{Rails.root}/db/seeds/breeding_site"
require "#{Rails.root}/db/seeds/documentation_section"

#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding countries..."
puts "\n" * 3

countries = ["Brazil", "Mexico"]
countries.each do |c_name|
  c = Country.find_by_name(c_name)
  if c.nil?
    c = Country.new
    c.name = c_name
    c.save!
  end
end

puts "-" * 80
puts "[!] Seeding cities..."
puts "\n" * 3

cities = [
  { :name => "Rio de Janeiro", :state => "Rio de Janeiro", :state_code => "RJ", :country_name => "Brazil" },
  { :name => "Tepalcingo", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" },
  { :name => "Cuernavaca", :state => "Morelos", :state_code => "MOR", :country_name => "Mexico" }
]
cities.each do |c_hash|
  c = City.find_by_name( c_hash[:name] )
  if c.nil?
    c = City.new
    c.name = c_hash[:name]
    c.state = c_hash[:state]
    c.state_code = c_hash[:state_code]
    c.country_id = Country.find_by_name( c_hash[:country_name] ).id
    c.save!
  end
end


puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

communities = [
  {:name => "Maré",         :city_name => "Rio de Janeiro"},
  {:name => "Tepalcingo",   :city_name => "Tepalcingo"},
  {:name => "Ocachicualli", :city_name => "Cuernavaca"}
]
communities.each do |c_hash|
  n = Neighborhood.find_by_name( c_hash[:name] )
  if n.nil?
    n                   = Neighborhood.new
    n.name              = c_hash[:name]
    n.city_id           = City.find_by_name( c_hash[:city_name] ).id
    n.save!
  end
end


puts "\n" * 3
puts "[ok] Done seeding countries, cities, and neighborhoods..."
puts "-" * 80

#------------------------------------------------------------------------------
# Elimination types and methods

seed_breeding_sites_and_elimination_methods()

#------------------------------------------------------------------------------
# Manual

seed_manual()

puts "\n" * 3
puts "[...] Seeding /howto documentation in Spanish"
puts "-" * 80

Rake::Task["documentation_sections:add_spanish_translation"].invoke

puts "\n" * 3
puts "[ok] Done seeding /howto documentation in Spanish"
puts "-" * 80

#------------------------------------------------------------------------------
