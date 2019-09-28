# This module abstracts the notion of a green locations rankings table by
# using Redis in-memory datastore to store rankings. Use this method
# to retrieve top 5 results, and use this method to periodically store
# new rankings (run via a Sidekiq job).

module GreenLocationRankings
  def self.add_score_to_user(score, user)
    $redis_pool.with do |redis|
      redis.zadd(self.redis_key_for_city(user.city), score, user.id)
    end
  end

  def self.score_for_user(user)
    $redis_pool.with do |redis|
      redis.zscore(self.redis_key_for_city(user.city), user.id)
    end
  end

  def self.top_ten_for_city(city)
    users = []
    $redis_pool.with do |redis|
      users = redis.zrevrange(self.redis_key_for_city(city), 0, 20, :with_scores => true).map {|id, score| {:user => User.find_by_id(id), :score => score} }
    end

    #users.reject! { |user| user[:user] && user[:user].coordinator? }
    return users[0..4]
  end

  def self.redis_key_for_city(city)
    "green_location_rankings:#{city.name.strip.downcase}"
  end
end
