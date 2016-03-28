json.array! @locations do |loc|
  json.(loc, :id, :latitude, :longitude)

  types = loc.inspection_types
  json.positive  types[Inspection::Types::POSITIVE]
  json.potential types[Inspection::Types::POTENTIAL]
  json.negative  types[Inspection::Types::NEGATIVE]
end
