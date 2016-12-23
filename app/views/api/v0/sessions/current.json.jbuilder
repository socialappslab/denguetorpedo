json.user do
  json.(@current_user, :id, :neighborhood)
  json.neighborhoods @current_user.city.neighborhoods.order("name ASC").as_json(:only => [:id, :name])
end
