json.(user, :id)
json.display_name user.display_name
json.photo        ActionController::Base.helpers.asset_path(user.picture)
json.url          user_path(user)

#-------------
# Associations
#-------------
json.neighborhood do
  json.geographical_display_name user.neighborhood.geographical_display_name
  json.url neighborhood_path(user.neighborhood)
end
