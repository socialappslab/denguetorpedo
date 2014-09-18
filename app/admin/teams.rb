ActiveAdmin.register Team do
  index do
    column "name"
    column "neighborhood" do |team|
      Neighborhood.find(team.neighborhood_id).name
    end

    column "blocked"
    column "created_at"

    default_actions
  end

  form do |f|
    f.inputs "Details" do
      f.input "name"
      f.input "blocked"
      f.input "neighborhood_id", :as => :select, :collection => Neighborhood.all.map {|n| [n.name, n.id]}, :include_blank => false
    end

    f.actions
  end
end
