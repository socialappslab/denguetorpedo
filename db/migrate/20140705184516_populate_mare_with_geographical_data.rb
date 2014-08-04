# encoding: UTF-8

class PopulateMareWithGeographicalData < ActiveRecord::Migration
  def up
    # Mare is located in the city of Rio de Janeiro, in the same state,
    # in Brazil.
    mare                   = Neighborhood.find_by_name("Maré")
    return if mare.nil?

    country                = Country.find_country_by_name("Brazil")
    mare.country_string_id = country.alpha2
    mare.state_string_id   = "RJ"
    mare.city              = "Rio de Janeiro"
    mare.save!
  end

  def down
  end
end
