json.locations @locations do |location|
  json.partial! "api/v0/locations/location", :location => location

  json.green location.green?

  visits = location.visits.order("visited_at DESC")
  json.last_visited_at visits.first && visits.first.visited_at.strftime("%Y-%m-%d")

  json.visits location.visits.order("visited_at ASC").includes(:inspections) do |visit|
    json.partial! "api/v0/visits/visit", :visit => visit
  end
end
