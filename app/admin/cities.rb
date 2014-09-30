ActiveAdmin.register City do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
    column "state"
    column "state_code"
    column "country_id"
    column "photo"
    default_actions
  end

  #----------------------------------------------------------------------------
  # Controller customizations
  #--------------------------
  controller do
    with_role :admin
  end

  #----------------------------------------------------------------------------
  # View customizations
  #--------------------
  form do |f|
    f.inputs "Details" do
      f.input "name"
      f.input "state"
      f.input "state_code"
      f.input "country_id", :as => :select, :collection => Country.all.map {|c| [c.name, c.id]}
      f.input "photo"
    end
    f.actions
  end

end
