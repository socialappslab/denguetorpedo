# The pool configuration is set to 20 *per process*
# because that's what the basic plan allows on Heroku.
# As long as we run Puma and Sidekiq in 2 separate processes,
# we should be fine setting thread-level concurrency to at
# most 20.
database_url = ENV['DATABASE_URL']
if(database_url)
  ENV['DATABASE_URL'] = "#{database_url}?pool=20"
  ActiveRecord::Base.establish_connection
end
