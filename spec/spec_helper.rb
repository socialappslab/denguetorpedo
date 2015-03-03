# This file is copied to spec/ when you run 'rails generate rspec:install'

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'database_cleaner'

require "rake"

require 'sidekiq/testing/inline'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

#------------------------------------------------------------------------------
# Capybara configuration
#-----------------------
# The test server runs on port 9000, separate from the dev server.
Capybara.server_port = 9000
Capybara.app_host    = "http://localhost:#{Capybara.server_port}"
Capybara.asset_host  = "http://localhost:5000"

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = true
end

# Set the default JavaScript driver.
require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, { :js_errors => false, :window_size => [1440, 900] })
end
Capybara.javascript_driver = :poltergeist

#------------------------------------------------------------------------------

RSpec.configure do |config|
  # This option ensures that we fail fast. It mimicks the hooks.rb behavior for our Cucumber suite.
  # Run specs in random order to surface order dependencies.
  # To debug an order dependency, use the seed, printed after each run.
  #     --seed 1234
  config.fail_fast     = true
  config.color_enabled = true
  config.order = "random"

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # DO NOT run performance tests by default.
  config.filter_run_excluding :performance => true

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # DatabaseCleaner configuration
  config.before(:suite) do
    # Before starting the suite, wipe the DB clean, then seed it.
    DatabaseCleaner.clean_with(:truncation)
    load Rails.root.join("db", "seeds.rb")
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :after_commit => true) do
    DatabaseCleaner.strategy = :truncation, { :except => %w[breeding_sites countries cities elimination_methods neighborhoods] }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
