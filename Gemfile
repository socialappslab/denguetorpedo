source 'http://rubygems.org'

ruby "1.9.3"
gem 'rails', '~> 3.2.1'

group :staging, :production do
  gem 'pg'
end

#------------------------------------------------------------------------------
# Encoding support

gem 'magic_encoding'

#------------------------------------------------------------------------------
# Maps

gem 'geokit'
gem 'leaflet-rails'

#------------------------------------------------------------------------------
# SMS communication

gem 'nexmo'
gem 'mms2r'

#------------------------------------------------------------------------------
# PDF-related

gem 'prawn'
gem 'prawn-layout'
gem "prawnto_2", :require => "prawnto"

#------------------------------------------------------------------------------
# Internationalization

gem 'rails-i18n'

#------------------------------------------------------------------------------
# Front-end tools

gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dynamic_form'

#------------------------------------------------------------------------------

gem 'ruby-gmail'
gem 'mime'
gem 'bcrypt-ruby', '~> 3.0.0'
gem 'therubyracer' # this is required for the coffeescript compiler to work on linux
gem 'simple_enum'
gem 'awesome_nested_set'
gem 'uuid'
gem 'eventmachine', '~> 1.0.0.beta.4.1'
gem 'cancan'
gem 'rails_autolink'


#------------------------------------------------------------------------------
# Assets

group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'bootstrap-sass', '~> 2.0.3'
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', '>= 1.0.3'
end

gem 'yui-compressor'

#------------------------------------------------------------------------------
# Image Management and Processing

gem 'aws-sdk'
gem 'rmagick'
gem 'paperclip', :git => 'git://github.com/thoughtbot/paperclip'

#------------------------------------------------------------------------------
# Server Management

gem "puma"
gem "foreman"

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
  gem 'launchy'          # a useful debugging aid for user stories
  gem 'sqlite3'
end

group :test do
  gem 'guard-rspec'
  gem 'database_cleaner'
  gem 'faker'
end

#------------------------------------------------------------------------------
