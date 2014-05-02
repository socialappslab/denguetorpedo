# encoding: UTF-8

def populate_notices
  mare = Neighborhood.find_by_name('Maré')

  10.times do |index|
    Notice.create!(:neighborhood_id => mare.id, :title => "Hello News ##{index}!", :description => "We are now live for the #{index}th time!")
  end
end


def populate_houses
  mare = Neighborhood.find_by_name('Maré')

  5.times do |index|
    House.create!(:neighborhood_id => mare.id, :name => "House #{index}!")
  end

  House.create!(:neighborhood_id => mare.id, :name => "House Sponsor!", :house_type => "lojista")
end
