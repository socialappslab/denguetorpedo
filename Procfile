web: bundle exec puma  -t 0:16 -p $PORT -e ${RACK_ENV:-development}

# TODO: We're turning this off until we're ready to pay
# for Heroku's worker process. Until then, we're not
# going to be processing map coordinates in the background.
# worker: bundle exec sidekiq -c 10 -q map_coordinates
