ActiveAdmin.register DocumentationSection do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "title"
    column "title_in_es"
    column "content"
    column "content_in_es"
    default_actions
  end

  #----------------------------------------------------------------------------
  # View customizations
  #--------------------
  form do |f|
    f.inputs "Details" do
      f.input "title"
      f.input "title_in_es"
      f.input "content"
      f.input "content_in_es"
    end
    f.actions
  end
end
