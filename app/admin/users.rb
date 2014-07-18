ActiveAdmin.register User, :as => "User" do
  index do
    column "email"
    column "phone_number"
    column "points"
    column "is_verifier"
    column "is_fully_registered"
    column "is_health_agent"
    column "first_name"
    column "middle_name"
    column "last_name"
    column "nickname"
    column "display"
    column "username"
    column "role"
    column "total_points"
    column "gender"
    column "is_blocked"
    column "carrier"
    column "prepaid"
    column "neighborhood_id"

    column "created_at"
    column "updated_at"

    default_actions
  end


  form do |f|
    f.inputs "Details" do
      f.input "email"
      f.input "phone_number"
      f.input "points"
      f.input "is_verifier"
      f.input "is_fully_registered"
      f.input "is_health_agent"
      f.input "first_name"
      f.input "middle_name"
      f.input "last_name"
      f.input "nickname"
      f.input "display"
      f.input "username"
      f.input "role"
      f.input "total_points"
      f.input "gender"
      f.input "is_blocked"
      f.input "carrier"
      f.input "prepaid"
      f.input "neighborhood_id"
    end

    f.actions
  end
end
