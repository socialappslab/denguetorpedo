# -*- encoding : utf-8 -*-

require "rails_helper"

describe Prize do
  let(:user)   { FactoryGirl.create(:user,  :neighborhood_id => Neighborhood.first.id)  }
  let(:prize)  { FactoryGirl.create(:prize, :user_id => user.id, :neighborhood_id => Neighborhood.first.id) }

  it "calculates valid expiration" do
    expect(prize.expired?).to eq(false)
  end

  it "identifies expired timestamp" do
    prize.update_attribute(:expire_on, Time.zone.now - 7.days)
    expect(prize.reload.expired?).to eq(true)
  end

  it "identifies empty stock" do
    prize.update_attribute(:stock, 0)
    expect(prize.reload.expired?).to eq(true)
  end
end
