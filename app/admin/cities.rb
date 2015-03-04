ActiveAdmin.register City do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
    column "state"
    column "state_code"
    column "country"
    column "photo"
    column "time_zone"
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
      f.input "country", :as => :select, :collection => [City::Countries::BRAZIL, City::Countries::MEXICO, City::Countries::NICARAGUA]
      f.input "photo"
      f.input "time_zone", :as => :select, :collection => TZInfo::Timezone.all.map{ |tz| [tz.name, tz.name] };
    end
    f.actions
  end

end
