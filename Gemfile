source 'http://rubygems.org'

ruby '2.1.2'

# Analytics
gem "analytics-ruby", '~> 2.0.8', :require => false
gem 'angularjs-rails'

# File management and manipulation
# TODO: Update AWS to handle new versions
# See: http://stackoverflow.com/questions/28374401/nameerror-uninitialized-constant-paperclipstorages3aws
gem 'aws-sdk', '< 2.0'

gem 'bcrypt-ruby', '~> 3.1.2'
gem 'bootstrap-sass', '~> 3.2.0'

# TODO: Should we deprecate this? The only place where we use CanCan is when
# initializing a user.
gem 'cancan'
gem 'coffee-rails'
gem "connection_pool"

gem "devise-i18n"

gem "figaro"
gem "foreman"

gem 'haml'
gem "http_accept_language"
gem "jbuilder"
gem 'paperclip', '~> 4.2.0'
gem "pg"
# Needed for a smooth upgrade from Rails 3.2 to Rails 4.0
# http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html
gem 'protected_attributes'
gem "puma"
gem "pundit"
gem 'rails', "4.2"
gem 'rails_autolink'
gem 'rails-i18n'
gem "roo", :require => false
gem 'sass-rails', "~> 5.0"
gem "sidekiq"
gem 'sinatra', :require => nil
gem 'uglifier', '>= 1.0.3'
gem "yuicompressor"

#------------------------------------------------------------------------------

group :development do
  gem 'derailed_benchmarks', :git => "git@github.com:schneems/derailed_benchmarks.git", :require => false
  gem 'rack-mini-profiler', :require => false
  gem 'web-console', '~> 2.0'
end

#------------------------------------------------------------------------------

group :test do
  gem 'rspec-rails'
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

group :development, :staging, :production do
  # Caching
  # See: https://devcenter.heroku.com/articles/rack-cache-memcached-rails31
  gem 'rack-cache'
  gem 'dalli'
  gem 'kgio'
  gem "memcachier"
end

#------------------------------------------------------------------------------
