json.(@inspection, :id, :position, :identification_type)
json.color Inspection.color_for_inspection_status[@inspection.identification_type]

json.created_at @inspection.created_at

r = @inspection
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
