class MapCoordinatesWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :map_coordinates, :retry => true, :backtrace => true

  def perform(report_id)
    # An exception will be raised if this instance hasn't been persisted yet.
    report = Report.find(report_id)

    # If the report doesn't have a location or the location already has map
    # coordinates, then let's go ahead and exit.
    return if report.location.blank?
    return if report.location.latitude.present? && report.location.longitude.present?


    # At this point, we know that both lat/long are missing so we need to fetch
    # them via the server.
    server_url         = "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates"
    escaped_server_url = URI.escape("#{server_url}?f=pjson&Street=#{report.location.address}")
    parsed_server_url  = URI.parse(escaped_server_url)

    # If the response returns no candidates, then let's raise an error so
    # that Sidekiq retries again.
    response = JSON.parse(Net::HTTP.get(parsed_server_url)) #["candidates"].first
    raise "No candidate found for location with id: #{report.location.id} and address: #{report.location.address}" if response["candidates"].blank?

    puts "response: #{response.inspect}"
    candidate = response["candidates"].first

    report.latitude  = candidate["location"]["x"]
    report.longitude = candidate["location"]["y"]

    report.save!
  end
end
