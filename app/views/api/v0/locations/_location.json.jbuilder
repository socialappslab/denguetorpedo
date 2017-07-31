json.(location, :id, :neighborhood_id, :address, :latitude, :longitude)
json.questions location.questionnaire_with_answers(@current_user.selected_membership)

json.neighborhood do
  n = location.neighborhood
  json.name n.name
  json.path neighborhood_path(n)
end

json.user_id @current_user.id
