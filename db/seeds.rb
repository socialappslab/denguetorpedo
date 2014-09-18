# encoding: UTF-8

require "#{Rails.root}/db/seeds/breeding_site"
require "#{Rails.root}/db/seeds/documentation_section"

#------------------------------------------------------------------------------
# Neighborhoods

puts "-" * 80
puts "[!] Seeding neighborhoods..."
puts "\n" * 3

communities = [
  {:name => "Maré",         :city => "Rio de Janeiro", :state_string_id => "RJ",  :country => "Brazil"},
  {:name => "Tepalcingo",   :city => "Tepalcingo",     :state_string_id => "MOR", :country => "Mexico"},
  {:name => "Ocachicualli", :city => "Cuernavaca",     :state_string_id => "MOR", :country => "Mexico"}
]

communities.each do |c|
  n = Neighborhood.find_by_name( c[:name] )
  if n.nil?
    country = Country.find_country_by_name( c[:country] )
    n                   = Neighborhood.new
    n.name              = c[:name]
    n.city              = c[:city]
    n.state_string_id   = c[:state_string_id]
    n.country_string_id = country.alpha2
    n.save!
  end
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
