# We're using a Redis pool instead of a single connection because we're using a
# multi-threaded environment with Puma. See
# https://github.com/mperham/sidekiq/wiki/Advanced-Options#connection-pooling
# and
# http://stackoverflow.com/questions/28113940/what-is-the-best-way-to-use-redis-in-a-multi-threaded-rails-environment-puma
# for reasoning.
$redis_pool = ConnectionPool.new(size: 10, timeout: 5) { Redis.new(:url => ENV["REDISTOGO_URL"]) }
