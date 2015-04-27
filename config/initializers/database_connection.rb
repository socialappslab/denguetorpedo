# -*- encoding : utf-8 -*-
# The pool configuration is set to 20 *per process*
# because that's what the basic plan allows on Heroku.
# As long as we run Puma and Sidekiq in 2 separate processes,
# we should be fine setting thread-level concurrency to at
# most 20.
# database_url = ENV['DATABASE_URL']
# if(database_url)
#   ENV['DATABASE_URL'] = "#{database_url}?pool=20"
#   ActiveRecord::Base.establish_connection
# end


# New database configuration via
# http://blog.codeship.com/puma-vs-unicorn/#comment-1743800292
# and
# https://devcenter.heroku.com/articles/concurrency-and-database-connections
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect!

  ActiveSupport.on_load(:active_record) do
    if config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
      config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
      config['pool']              = ENV['DB_POOL']      || ENV['MAX_THREADS'] || 5
      ActiveRecord::Base.establish_connection(config)
    end
  end
end
