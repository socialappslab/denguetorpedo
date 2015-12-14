module Hashtag
  TESTIMONIAL = "testimonial"

  def self.posts_for_hashtag(hashtag)
    ids = []
    $redis_pool.with do |redis|
      ids = redis.smembers self.redis_key(hash)
    end

    Post.where(:id => ids)
  end

  def self.add_post_to_hashtag(post, hashtag)
    $redis_pool.with do |redis|
      redis.sadd(self.redis_key(hash), post.id)
    end
  end

  def self.remove_post_from_hashtag(post, hashtag)
    $redis_pool.with do |redis|
      redis.srem(self.redis_key(hash), post.id)
    end
  end

  # This key holds the set of all post ids that have this hashtag.
  def self.redis_key(hashtag)
    "hashtags:#{hashtag}"
  end
end
