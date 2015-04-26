# -*- encoding : utf-8 -*-
# require "sidekiq"

# class MapCoordinatesWorker
#   include Sidekiq::Worker
#
#   sidekiq_options :queue => :map_coordinates, :retry => true, :backtrace => true
#
#   def perform(location_id)
#     # An exception will be raised if the instance hasn't been persisted yet.
#     location = Location.find(location_id)
#
#     # If the location already has map coordinates, then let's go ahead and exit.
#     return if location.latitude.present? && location.longitude.present?
#
#     # At this point, we know that both lat/long are missing so we need to fetch
#     # them via the server.
#     escaped_server_url = URI.escape("#{Location::BASE_URI}?f=pjson&Street=#{location.address}")
#     parsed_server_url  = URI.parse(escaped_server_url)
#
#     # If the response returns no candidates, then let's raise an error so
#     # that Sidekiq retries again.
#     response = JSON.parse(Net::HTTP.get(parsed_server_url))
#     raise "No candidate found for location with id: #{location.id} and address: #{location.address}" if response["candidates"].blank?
#
#     # Return the most likely candidate and update the Location instance.
#     candidate = response["candidates"].first
#
#     location.latitude  = candidate["location"]["x"]
#     location.longitude = candidate["location"]["y"]
#
#     location.save!
#   end
# end
