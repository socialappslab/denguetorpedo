ActiveAdmin.register Country do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "name"
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
    end
    f.actions
  end

end
