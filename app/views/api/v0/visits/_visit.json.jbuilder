json.(visit, :id, :location_id, :classification, :color)
json.visited_at visit.visited_at.strftime("%Y-%m-%d")

json.location do
  json.(visit.location, :id, :address)
end

json.inspections visit.inspections.includes(:report).order("position ASC") do |ins|
  json.(ins, :id, :position, :identification_type)
  json.color Inspection.color_for_inspection_status[ins.identification_type]

  r = ins
  json.set! :report do
    json.(r, :field_identifier, :eliminated_at, :description, :protected, :chemically_treated, :larvae, :pupae)

    json.report r.description

    json.before_photo r.breeding_site_picture
    json.after_photo  r.elimination_method_picture

    json.breeding_site do
      json.(r.breeding_site, :id, :code)
      json.description r.breeding_site.description_in_es
    end

    if r.elimination_method.present?
      json.elimination_method do
        json.(r.elimination_method, :id)
        json.description r.elimination_method.description_in_es
      end
    end

  end
end
