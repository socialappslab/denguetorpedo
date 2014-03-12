web: bundle exec puma  -t 0:16 -p $PORT -e ${RACK_ENV:-development}
worker: bundle exec sidekiq -c 10 -q map_coordinates
