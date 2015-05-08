# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Location do

  it 'creates location from a generic address string' do
    lambda {
      l = Location.create(address: "Rua Tatajuba 50", :neighborhood_id => 1)
    }.should change(Location, :count).by(1)
  end
end
