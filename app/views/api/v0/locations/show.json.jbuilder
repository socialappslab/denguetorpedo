json.location do
  json.(@location, :id, :neighborhood_id, :address, :latitude, :longitude)

  json.visits @location.visits.order("visited_at DESC").includes(:inspections) do |visit|
    json.(visit, :id, :classification, :color)
    json.visited_at visit.visited_at.strftime("%Y-%m-%d")

    json.inspections_count visit.inspections.count
  end

end

json.location_questions HouseQuiz.questions.as_json
