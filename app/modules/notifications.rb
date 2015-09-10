module Notifications
  module Action
    LIKE    = "like"
    COMMENT = "comment"
  end

  def add_notification(item, action, user)
    notify_json = Notifications.notification_json(item, action, user)

    # We add the notification only if it hasn't been added yet.
    $redis_pool.with do |redis|
      redis.lpush(self.redis_key_for_notifications, notify_json)
    end
  end

  # We clear a notification if the user visits the path that corresponds to that
  # notification.
  def remove_notification(item, action, user)
    notify_json = Notifications.notification_json(item, action, user)

    $redis_pool.with do |redis|
      redis.lrem(self.redis_key_for_notifications, 0, notify_json)
    end
  end

  def get_notifications
    notifications = []
    $redis_pool.with do |redis|
      notifications = redis.lrange(self.redis_key_for_notifications, 0, -1)
    end

    return notifications.map! {|n| JSON.parse(n)}
  end

  def self.notification_json(item, action, user)
    return {:user => user.id, :notifiable_id => item.id, :notifiable_type => item.class.name, :action => action}.to_json
  end

  def redis_key_for_notifications
    "user:#{self.id}:notifications"
  end
end
