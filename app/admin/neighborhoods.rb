ActiveAdmin.register Neighborhood do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
    column "city_id"
    column "created_at"
    column "updated_at"
    column "photo"
    column "latitude"
    column "longitude"
    default_actions
  end

  #----------------------------------------------------------------------------
  # Controller customizations
  #--------------------------
  controller do
    with_role :admin
    helper "active_admin/neighborhoods"
  end

  #----------------------------------------------------------------------------
  # View customizations
  #--------------------
  form do |f|
    f.inputs "Details" do
      f.input "name"
      f.input "city_id", :as => :select, :collection => City.all.map {|c| [c.name, c.id]}
      f.input "photo"
      f.input "latitude"
      f.input "longitude"
    end
    f.actions
  end


end
