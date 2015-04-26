source 'http://rubygems.org'

ruby "2.0.0"
gem 'rails', '~> 3.2.18'

gem 'pg'

#------------------------------------------------------------------------------
# Encoding support

gem 'magic_encoding'
gem 'mime' # TODO: Possibly deprecate?

#------------------------------------------------------------------------------
# User management

gem 'bcrypt-ruby', '~> 3.0.0'
gem 'cancan'

#------------------------------------------------------------------------------
# Email communication

gem 'ruby-gmail'

#------------------------------------------------------------------------------
# Internationalization

gem 'rails-i18n'
gem "devise-i18n"
gem "http_accept_language"

#------------------------------------------------------------------------------
# Front-end tools

gem 'haml'
# gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dynamic_form'
gem 'rails_autolink'

#------------------------------------------------------------------------------
# Assets

gem 'yui-compressor'
group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'bootstrap-sass', '~> 3.2.0'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
  gem "yuicompressor"
end

#------------------------------------------------------------------------------
# File management

gem 'aws-sdk'
gem 'rmagick'
gem 'paperclip', '~> 4.2.0'
gem "roo"

#------------------------------------------------------------------------------
# Server Management

gem "puma"
gem "foreman"
gem "therubyracer"
gem "rack-timeout"

#------------------------------------------------------------------------------
# Caching
# See: https://devcenter.heroku.com/articles/rack-cache-memcached-rails31

gem 'rack-cache'
gem 'dalli'
gem 'kgio'
gem "memcachier"

#------------------------------------------------------------------------------
# Workers

gem "sidekiq"
gem 'sinatra', '>= 1.3.0', :require => nil

#------------------------------------------------------------------------------
# Testing

group :test, :development do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'         # lets Cucumber pretend to be a web browser
  gem 'sqlite3'
end

group :test do
  gem 'guard-rspec'
  gem 'database_cleaner'
  gem 'faker'
  gem 'launchy'
  gem "poltergeist"
end

#------------------------------------------------------------------------------
# Administration

gem "activeadmin"

#------------------------------------------------------------------------------
# TODO

# TODO: Deprecate after refactoring Post model.
gem 'awesome_nested_set'

# TODO: Deprecate after refactoring Feed model.
gem 'simple_enum'

#------------------------------------------------------------------------------
# Heroku-specific gems

group :production, :staging do
  gem "rails_12factor"
end

#------------------------------------------------------------------------------
# Analytics & Profiling

gem 'newrelic_rpm'
gem "analytics-ruby", '~> 2.0.8'
gem 'rack-mini-profiler', :require => false
