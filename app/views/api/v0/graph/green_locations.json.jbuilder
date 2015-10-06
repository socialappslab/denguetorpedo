json.green_locations @series do |series|
  json.count series[:green_houses].to_i

  if series[:date].year == Time.now.year
    json.start_week series[:date].beginning_of_week.strftime("%m-%d")
    json.end_week series[:date].end_of_week.strftime("%m-%d")
  else
    json.start_week series[:date].beginning_of_week.strftime("%Y-%m-%d")
    json.end_week series[:date].end_of_week.strftime("%Y-%m-%d")
  end

end
