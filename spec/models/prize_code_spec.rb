# -*- encoding : utf-8 -*-

require "rails_helper"

describe PrizeCode do
  let(:user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:prize)  { FactoryGirl.create(:prize, :user_id => user.id, :neighborhood_id => Neighborhood.first.id) }
  let(:coupon) { FactoryGirl.create(:prize_code, :user_id => user.id, :prize_id => prize.id) }

  it "calculates valid coupons" do
    expect(coupon.expired?).to eq(false)
  end

  it "calculates expired coupons" do
    coupon = FactoryGirl.create(:prize_code, :created_at => 8.days.ago, :user_id => user.id, :prize_id => prize.id)
    expect(coupon.expired?).to eq(true)
  end

  it "identifies expired coupons if the prize has expired" do
    prize.update_attribute(:stock, 0)
    expect(coupon.reload.expired?).to eq(true)
  end

  it "identifies expired coupons if the prize has expired" do
    prize.update_attribute(:expire_on, 7.days.ago)
    expect(coupon.reload.expired?).to eq(true)
  end

  it "identifies redeemed coupons" do
    coupon.update_attribute(:redeemed, true)
    expect(coupon.reload.is_redeemed?).to eq(true)
  end
end
