json.(visit, :id, :location_id, :classification, :color)
json.visited_at visit.visited_at.strftime("%Y-%m-%d")

json.location do
  json.(visit.location, :id, :address)
end

json.inspections visit.inspections.includes(:report).order("position ASC") do |ins|
  json.(ins, :id, :position, :identification_type)
  json.color Inspection.color_for_inspection_status[ins.identification_type]

  json.created_at ins.report.created_at

  if r = ins.report
    json.set! :report do
      json.partial! "api/v0/sync/report", :r => r
    end
  end
end
