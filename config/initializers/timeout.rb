# Use Rack::Timeout to time out Puma workers. See
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server
# for more.
Rack::Timeout.timeout = 20 # seconds
