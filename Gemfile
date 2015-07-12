source 'http://rubygems.org'

gem 'rails', '~> 3.2.18'

# Server Management
gem "pg"
gem "puma"
gem "foreman"
gem "therubyracer"

gem 'angularjs-rails'

# Middleware hacks
gem "rack-timeout"

# Background jobs
gem "sidekiq"

# JSON
gem "jbuilder"

gem "pundit"

# File management and manipulation
# TODO: Update AWS to handle new versions
# See: http://stackoverflow.com/questions/28374401/nameerror-uninitialized-constant-paperclipstorages3aws
gem 'aws-sdk', '< 2.0'
gem 'rmagick'
gem 'paperclip', '~> 4.2.0'

gem "roo", :require => false

# Administration
gem "activeadmin"

# Analytics
gem "analytics-ruby", '~> 2.0.8', :require => false

# Internationalization
gem 'rails-i18n'
gem "devise-i18n"
gem "http_accept_language"

# Front-end tools
gem 'haml'
gem 'jquery-ui-rails'
gem 'rails_autolink'

# User management
gem 'bcrypt-ruby', '~> 3.0.0'

# TODO: Should we deprecate this? The only place where we use CanCan is when
# initializing a user.
gem 'cancan'

# Sidekiq Monitoring
gem 'sinatra', :require => nil

#------------------------------------------------------------------------------

group :development, :staging, :production do
  # Caching
  # See: https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
  gem 'rack-cache'
  gem 'dalli'
  gem 'kgio'
  gem "memcachier"
end

#------------------------------------------------------------------------------

group :development do
  gem 'derailed_benchmarks', :git => "git@github.com:schneems/derailed_benchmarks.git", :require => false
  gem 'rack-mini-profiler', :require => false
end

#------------------------------------------------------------------------------

group :test do
  gem 'rspec-rails', "~> 3.2"
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'database_cleaner'
  gem 'faker'
  gem 'launchy', :require => false
  gem "poltergeist"
end

#------------------------------------------------------------------------------

group :production, :staging do
  gem "rails_12factor"
  gem "newrelic_rpm"
end

#------------------------------------------------------------------------------

group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'bootstrap-sass', '~> 3.2.0'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
  gem "yuicompressor"
end

#------------------------------------------------------------------------------
