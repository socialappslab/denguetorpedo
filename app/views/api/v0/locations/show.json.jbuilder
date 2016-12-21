json.visits @location.visits.order("visited_at ASC").includes(:inspections) do |visit|
  json.timestamp  format_csv_timestamp(visit.visited_at)
  json.colors visit.inspection_types.select {|k,v| v}.map {|k,v| color_for_inspection_status(k)}

  json.inspections visit.inspections.includes(:report).order("position ASC") do |ins|
    json.(ins, :identification_type)
    json.color color_for_inspection_status(ins.identification_type)

    if r = ins.report
      json.set! :report do
        json.set! :field_identifier, r.field_identifier
        json.set! :breeding_site, (r.breeding_site && r.breeding_site.code)
      end
    end
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
