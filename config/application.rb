# -*- encoding : utf-8 -*-

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups)
end

module Dengue
  class Application < Rails::Application

    # Comress HTML and JS/CSS using gzip and deflate. See:
    # https://robots.thoughtbot.com/content-compression-with-rack-deflater
    # config.middleware.use Rack::Deflater

    # DEPRECATION WARNING: Currently, Active Record suppresses errors raised within
    # `after_rollback`/`after_commit` callbacks and only print them to the logs.
    # In the next version, these errors will no longer be suppressed. Instead,
    # the errors will propagate normally just like in other Active Record callbacks.
    # You can opt into the new behavior and remove this warning by setting:
    config.active_record.raise_in_transactional_callbacks = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = "es"

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Use a different cache store in production
    config.cache_store = :dalli_store

    # heroku cedar stack assets fix
    config.assets.initialize_on_precompile = false

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        feature_specs: true,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end


    # Required code to make HAML templates work with Rails 3.2 asset compilation.
    # See http://stackoverflow.com/questions/7770327/adding-haml-to-the-rails-asset-pipeline
    config.assets.paths << Rails.root.join("app", "assets", "templates")

    # See https://gist.github.com/anotheruiguy/7379570
    config.assets.paths << Rails.root.join("app", "assets", "fonts")


    class HamlTemplate < Tilt::HamlTemplate
      def prepare
        @options = @options.merge :format => :html5
        super
      end
    end

    config.before_initialize do |app|
      require 'sprockets'
      Sprockets::Engines #force autoloading
      Sprockets.register_engine '.haml', HamlTemplate
    end

    # NOTE: This is the long-term solution to using JwtAuth. For now,
    # we will decode and encode in the controller.
    # See: https://auth0.com/blog/ruby-authentication-secure-rack-apps-with-jwt/
    # config.middleware.use "JwtAuth"
  end
end
