ActiveAdmin.register Neighborhood do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
    column "city" do |c|
      City.find(c).name
    end
    column "created_at"
    column "updated_at"
    column "photo"
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
    end
    f.actions
  end


end
