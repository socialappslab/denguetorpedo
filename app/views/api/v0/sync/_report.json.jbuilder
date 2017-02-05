json.(r, :field_identifier, :eliminated_at, :report, :protected, :chemically_treated, :larvae, :pupae)

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
