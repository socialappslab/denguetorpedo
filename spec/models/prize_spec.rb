# encoding: utf-8

require 'spec_helper'

describe Prize do
  let(:user)   { FactoryGirl.create(:user)  }
  let(:prize)  { FactoryGirl.create(:prize) }

  it "calculates valid expiration" do
    expect(prize.expired?).to eq(false)
  end

  it "identifies expired timestamp" do
    prize.update_attribute(:expire_on, Time.now - 7.days)
    expect(prize.reload.expired?).to eq(true)
  end

  it "identifies empty stock" do
    prize.update_attribute(:stock, 0)
    expect(prize.reload.expired?).to eq(true)
  end
end
