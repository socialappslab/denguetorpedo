# -*- encoding : utf-8 -*-
require "rails_helper"

describe GreenLocationRankings do
  let(:community) {create(:neighborhood)}
  let(:user)      {build_stubbed(:user)}

  before(:each) do
    $redis_pool = ConnectionPool.new(size: 1, timeout: 2) { Redis.new(:url => "redis://localhost:9736/") }
  end

  after(:each) do
    $redis_pool.with {|redis| redis.flushall }
  end

  it "adds and returns score to user" do
    subject.add_score_to_user(100, user)
    expect(subject.score_for_user(user)).to eq(100)
  end

  it "returns correct top 10 list" do
    3.times do |index|
      u = create(:user, :neighborhood => community, :username => "user#{index}")
      subject.add_score_to_user(100 + index, u)
    end

    list = subject.top_ten_for_city(community.city)
    expect(list[0][:user].id).to eq(User.find_by_username("user2").id)
    expect(list[0][:score]).to eq(102)
    expect(list[1][:user].id).to eq(User.find_by_username("user1").id)
    expect(list[1][:score]).to eq(101)
    expect(list[2][:user].id).to eq(User.find_by_username("user0").id)
    expect(list[2][:score]).to eq(100)
  end

end
