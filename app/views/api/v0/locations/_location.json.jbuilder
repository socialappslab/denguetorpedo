json.(location, :id, :address)
json.neighborhood do
  n = location.neighborhood
  json.name n.name
  json.path neighborhood_path(n)
end
