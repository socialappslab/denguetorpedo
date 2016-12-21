json.visits @visits do |visit|
  json.(visit, :id)
  json.visited_at visit.visited_at.strftime("%Y-%m-%d")
  json.location visit.location && visit.location.address
  json.inspections visit.inspections.count
end
