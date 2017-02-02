json.(location, :id, :neighborhood_id, :address, :latitude, :longitude, :questions)
json.neighborhood do
  n = location.neighborhood
  json.name n.name
  json.path neighborhood_path(n)
end
