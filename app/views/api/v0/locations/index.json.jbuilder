json.locations @locations do |location|
  json.partial! "api/v0/locations/location", :location => location

  # json.green location.green?
  # json.barrel_reports location.reports.where(:breeding_site_id => BreedingSite.find_by_code("B").id) do |report|
  #   json.(report, :protected, :chemically_treated, :larvae, :pupae)
  # end

  json.visits location.visits.order("visited_at ASC").includes(:inspections) do |visit|
    json.timestamp  format_csv_timestamp(visit.visited_at)
    json.class      class_for_status(visit.identification_type)
    json.identification_type visit.identification_type

    json.inspections visit.inspections do |ins|
      json.(ins, :identification_type)
    end

    barrel_reports = visit.reports.where(:breeding_site_id => BreedingSite.find_by_code("B").id)
    json.barrel_reports do |report|
      json.total     barrel_reports.count
      json.protected barrel_reports.where(:protected => true).count
      json.unprotected barrel_reports.where(:protected => false).count
      json.larvae    barrel_reports.where(:larvae => true).count
      json.pupae     barrel_reports.where(:pupae => true).count
      json.chemically_treated    barrel_reports.where(:chemically_treated => true).count
    end
  end
end
