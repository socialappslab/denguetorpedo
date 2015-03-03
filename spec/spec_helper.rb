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

RSpec.configure do |config|
  # DO NOT run performance tests by default.
  config.filter_run_excluding :performance => true

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # NOTE: This must be on the top of RSpec declaration, above any other config.before
  # declaration.
  config.before(:suite) do
    # Before starting the suite, wipe the DB clean, then seed it.
    DatabaseCleaner.clean_with(:truncation)
    load Rails.root.join("db", "seeds.rb")
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # Fail fast.
  config.fail_fast = true

  # Run specs in random order to surface order dependencies.
  # To debug an order dependency, use the seed, printed after each run.
  #     --seed 1234
  config.order = "random"

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
