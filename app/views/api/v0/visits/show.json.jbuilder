json.visit do
  json.(@visit, :id)
  json.visited_at @visit.visited_at.strftime("%Y-%m-%d")
  json.location @visit.location && @visit.location.address
  json.inspections @visit.inspections.includes(:report).order("position ASC") do |ins|
    json.(ins, :identification_type)
    json.color Inspection.color_for_inspection_status[ins.identification_type]

    if r = ins.report
      json.set! :report do
        json.(r, :field_identifier, :report)
        json.breeding_site do
          json.code r.breeding_site && r.breeding_site.code
          json.description r.breeding_site.description_in_es
        end
      end
    end
  end

end
