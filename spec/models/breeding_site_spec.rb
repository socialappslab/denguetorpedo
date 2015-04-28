# -*- encoding : utf-8 -*-
require 'spec_helper'

describe BreedingSite do
  it "destroys all associated elimination method" do
    bs = FactoryGirl.create(:breeding_site)
    expect {
      bs.destroy
    }.to change(EliminationMethod, :count).by(-bs.elimination_methods.count)
  end
end
