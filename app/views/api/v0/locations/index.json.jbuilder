json.locations @locations do |location|
  json.partial! "api/v0/locations/location", :location => location

  json.visits location.visits.order("visited_at ASC").includes(:inspections) do |visit|
    json.timestamp  format_csv_timestamp(visit.visited_at)
    json.class      class_for_status(visit.identification_type)
    json.identification_type visit.identification_type

    json.inspections visit.inspections do |ins|
      json.(ins, :identification_type)
    end
  end
end
