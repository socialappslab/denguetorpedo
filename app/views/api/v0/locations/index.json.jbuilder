json.locations @locations do |location|
  json.partial! "api/v0/locations/location", :location => location


  json.barrel_reports location.reports.where(:breeding_site_id => BreedingSite.find_by_code("B").id) do |report|
    json.(report, :protected, :chemically_treated, :larvae, :pupae)
  end

  json.visits location.visits.order("visited_at ASC").includes(:inspections) do |visit|
    json.timestamp  format_csv_timestamp(visit.visited_at)
    json.class      class_for_status(visit.identification_type)
    json.identification_type visit.identification_type

    json.inspections visit.inspections do |ins|
      json.(ins, :identification_type)
    end
  end
end
