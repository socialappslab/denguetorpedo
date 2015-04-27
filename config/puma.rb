# -*- encoding : utf-8 -*-
# See:
# * https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
# * http://blog.codeship.com/puma-vs-unicorn/#comment-1743800292
workers Integer(ENV['PUMA_WORKERS'] || 2)
threads Integer(ENV['PUMA_THREADS']  || 1), Integer(ENV['PUMA_THREADS'] || 4)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['PUMA_THREADS'] || 5
    ActiveRecord::Base.establish_connection(config)
  end
end
