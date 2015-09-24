json.green_locations @series do |series|
  json.count series[:green_houses].to_i
  json.week I18n.t("api.graph.week_of", :week => series[:date].beginning_of_week.strftime("%Y-%m-%d"))
end
