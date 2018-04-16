
json.user do
  json.token @user.jwt_token
  json.(@user, :id, :name, :username, :email, :neighborhood_id, :display_name)
  json.picture @user.picture
  json.neighborhood do
    json.(@user.neighborhood, :id, :name, :city_id, :geographical_display_name)
    json.city do
      json.(@user.neighborhood.city, :name, :state, :country, :localized_country_name)
    end
  end

  if @user.selected_membership.present?
    json.visit_questionnaire    Visit.questionnaire_for_membership(@user.selected_membership)
    json.location_questionnaire Location.questionnaire_for_membership(@user.selected_membership)
  end

  json.city do
    json.(@user.neighborhood.city, :name, :state, :localized_country_name)
  end

  json.breeding_sites BreedingSite.order("description_in_es ASC") do |bs|
    json.(bs, :id, :description)
    json.elimination_methods bs.elimination_methods.order("description_in_es ASC") do |em|
      json.(em, :id, :description)
    end
  end

  json.breeding_sites_codes @user.selected_membership.organization.organizations_breeding_sites
  
  json.neighborhoods Neighborhood.order("name ASC") do |n|
    json.(n, :id, :name)
  end

  json.total_points @user.total_total_points
  json.green_locations GreenLocationRankings.score_for_user(@user).to_i
end
