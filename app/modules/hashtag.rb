module Hashtag
  def self.official_hashtags
    ["testimonio", "puntos"]
  end

  def self.post_ids_for_hashtag(hashtag)
    ids = []
    $redis_pool.with do |redis|
      ids = redis.smembers self.redis_key(hashtag)
    end

    return ids.compact
  end

  def self.add_post_to_hashtag(post, hashtag)
    $redis_pool.with do |redis|
      redis.sadd(self.redis_key(hashtag), post.id)
    end
  end

  def self.remove_post_from_hashtag(post, hashtag)
    $redis_pool.with do |redis|
      redis.srem(self.redis_key(hashtag), post.id)
    end
  end

  # This key holds the set of all post ids that have this hashtag.
  def self.redis_key(hashtag)
    hashtag.gsub!("#", "")
    "hashtags:#{hashtag}"
  end
end
