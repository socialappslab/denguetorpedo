web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 5 -q default -q csv_parsing -q ranking -q timeseries -q odk_parsing -L log/sidekiq.log
