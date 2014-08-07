module ActiveAdmin::NeighborhoodsHelper
  def available_countries
    return Country.all.find_all {|name, id| ["Brazil", "Mexico"].include?(name)}
  end

  #----------------------------------------------------------------------------

  def available_states
    states = []
    available_countries.each do |name, id|
      c = Country[id]
      states << [name, c.states.map {|key, hash| [hash["name"], key]}]

    end

    return states
  end

  #----------------------------------------------------------------------------

end
