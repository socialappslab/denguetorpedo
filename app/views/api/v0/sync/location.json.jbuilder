location = @location
json.location do
  json.(location, :id, :neighborhood_id, :address)
  json.neighborhood do
    json.id   location.neighborhood_id
    json.name location.neighborhood && location.neighborhood.name
  end

  json.green location.green?

  visits = location.visits.order("visited_at DESC")
  json.last_visited_at visits.first && visits.first.visited_at.strftime("%Y-%m-%d")
  json.visits_count visits.count
end

json.last_sync_seq @last_seq
json.last_synced_at @last_synced_at
