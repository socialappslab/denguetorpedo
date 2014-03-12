Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect!

  #
  ActiveSupport.on_load(:active_record) do

    # The pool configuration is set to 20 *per process*
    # because that's what the basic plan allows on Heroku.
    # As long as we run Puma and Sidekiq in 2 separate processes,
    # we should be fine setting thread-level concurrency to at
    # most 20.
    config = ActiveRecord::Base.configurations[Rails.env]
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
    config['pool']              = 20
    ActiveRecord::Base.establish_connection(config)
  end
end
