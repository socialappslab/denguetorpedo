# encoding: UTF-8

require "#{Rails.root}/db/seeds/breeding_site"
require "#{Rails.root}/db/seeds/documentation_section"

#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

n = Neighborhood.find_by_name("Maré")
if n.nil?
  c = Country.find_country_by_name("Brazil")
  n                   = Neighborhood.new
  n.name              = "Maré"
  n.city              = "Rio de Janeiro"
  n.state_string_id   = "RJ"
  n.country_string_id = c.alpha2
  n.save!
end

# Tepalcingo neighborhood is our first neighborhood in Mexico.
# It is located in the city of Tepalcingo, in the state of Morelos,
# in the country of Mexico.
n = Neighborhood.find_by_name("Tepalcingo")
if n.nil?
  c = Country.find_country_by_name("Mexico")
  n                   = Neighborhood.new
  n.name              = "Tepalcingo"
  n.city              = "Tepalcingo"
  n.state_string_id   = "MOR"
  n.country_string_id = c.alpha2
  n.save!
end


puts "\n" * 3
puts "[ok] Done seeding neighborhoods..."
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
