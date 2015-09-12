module Notifications
  module Action
    LIKE    = "like"
    COMMENT = "comment"
    MENTION = "mention"
  end

  def add_notification(item, action)
    $redis_pool.with do |redis|
      redis.sadd(self.redis_key_for_item_and_action(item, action), item.id) unless redis.sismember(self.redis_key_for_item_and_action(item, action), item.id)
    end
  end

  def comment_notifications
    ids = []
    $redis_pool.with do |redis|
      ids  = redis.smembers(self.redis_key + ":comment.#{Action::LIKE}")
      ids += redis.smembers(self.redis_key + ":comment.#{Action::COMMENT}")
      ids += redis.smembers(self.redis_key + ":comment.#{Action::MENTION}")
    end

    return Comment.where(:id => ids)
  end

  def post_notifications
    ids = []
    $redis_pool.with do |redis|
      ids  = redis.smembers(self.redis_key + ":post.#{Action::LIKE}")
      ids += redis.smembers(self.redis_key + ":post.#{Action::COMMENT}")
      ids += redis.smembers(self.redis_key + ":post.#{Action::MENTION}")
    end

    return Post.where(:id => ids)
  end

  def remove_notifications(item)
    $redis_pool.with do |redis|
      redis.srem(self.redis_key_for_item_and_action(item, Action::LIKE), item.id)
      redis.srem(self.redis_key_for_item_and_action(item, Action::COMMENT), item.id)
      redis.srem(self.redis_key_for_item_and_action(item, Action::MENTION), item.id)
    end
  end

  def redis_key
    "user:#{self.id}:notifications"
  end

  def redis_key_for_item_and_action(item, action)
    self.redis_key + ":#{item.class.name.downcase}.#{action}"
  end
end
