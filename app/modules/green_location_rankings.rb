# This module abstracts the notion of a green locations rankings table by
# using Redis in-memory datastore to store rankings. Use this method
# to retrieve top 5 results, and use this method to periodically store
# new rankings (run via a Sidekiq job).

module GreenLocationRankings
  def self.add_score_to_user(score, user)
    $redis_pool.with do |redis|
      redis.zadd(self.redis_key, score, user.id)
    end
  end

  def self.score_for_user(user)
    $redis_pool.with do |redis|
      redis.zscore(self.redis_key, user.id)
    end
  end

  def self.top_ten
    $redis_pool.with do |redis|
      redis.zrevrange(self.redis_key, 0, 10, :with_scores => true).map {|id, score| {:user => User.find_by_id(id), :score => score} }
    end
  end

  def self.redis_key
    "green_location_rankings"
  end
end
