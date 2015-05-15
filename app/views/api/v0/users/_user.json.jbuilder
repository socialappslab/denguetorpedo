json.(user, :id)
json.display_name user.display_name

json.neighborhood do
  json.geographical_display_name user.neighborhood.geographical_display_name
end

# Paths
json.image_path ActionController::Base.helpers.asset_path(user.picture)
json.user_path  user_path(user)
json.neighborhood_path neighborhood_path(user.neighborhood)
