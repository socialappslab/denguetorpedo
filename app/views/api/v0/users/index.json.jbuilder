json.memberships @memberships do |m|
  json.(m, :user_id, :role, :blocked)

  json.user do
    user = m.user
    json.(user, :id, :email, :username, :full_name)
    json.neighborhood user.neighborhood.try(:name)
    json.edit_user_path edit_user_path(user)
  end
end
