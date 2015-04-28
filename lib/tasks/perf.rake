if Rails.env.development?
  require 'bundler'
  Bundler.setup

  require 'derailed_benchmarks'
  require 'derailed_benchmarks/tasks'

  TEST_COUNT=1
  PATH_TO_HIT="/"
end
