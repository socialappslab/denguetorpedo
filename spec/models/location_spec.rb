require 'spec_helper'

describe Location do

  it 'creates location from a generic address string' do
    lambda {
      l = Location.create(street_type: "Rua", street_name: "Tatajuba", street_number: "50")
      l.address = "Rua Tatajuba 50"
    }.should change(Location, :count).by(1)
  end

  it 'can fetch existing locations when one exists' do
    # l = Location.find_or_create('2521 Regent St. 94704')
    # Location.count.should == 1
    # l2 = Location.find_or_create('2655 Griffin Ave 90031')
    # Location.count.should == 2
    # Neighborhood.count.should == 2
    # l3 = Location.find_or_create('2521 Regent St. Berkeley CA 94704')
    # l3.should == l
    # Location.count.should == 2
    # Neighborhood.count.should == 2
  end
end
