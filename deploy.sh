#!/bin/bash
source /environment
RAILS_ENV=production
rake assets:precompile
bundle exec foreman start
