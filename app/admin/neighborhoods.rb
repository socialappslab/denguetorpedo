ActiveAdmin.register Neighborhood do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
    column "city"
    column "state_string_id"
    column "country_string_id"
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
      f.input "city"
      f.input "state_string_id", :as => :select, :collection => grouped_options_for_select(available_states)
      f.input "country_string_id", :as => :select, :collection => available_countries
      f.input "photo"
    end
    f.actions
  end


end
