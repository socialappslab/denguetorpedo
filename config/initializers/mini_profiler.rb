# -*- encoding : utf-8 -*-
if Rails.env.development?
  require 'rack-mini-profiler'

  # See
  # https://github.com/MiniProfiler/rack-mini-profiler#custom-middleware-ordering-required-if-using-rackdeflate-with-rails
  # for reasoning.
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rails.application.middleware.delete(Rack::MiniProfiler)
  # Rails.application.middleware.insert_after(Rack::Deflater, Rack::MiniProfiler)

  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
end
