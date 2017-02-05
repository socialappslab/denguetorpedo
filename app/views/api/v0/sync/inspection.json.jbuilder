json.(@inspection, :id, :position, :identification_type)
json.color Inspection.color_for_inspection_status[@inspection.identification_type]

json.created_at @inspection.report.created_at

if r = @inspection.report
  json.set! :report do
    json.partial! "api/v0/sync/report", :r => r
  end
end
