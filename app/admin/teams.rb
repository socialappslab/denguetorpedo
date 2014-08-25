ActiveAdmin.register Team do
  index do
    column "name"
    column "neighborhood_id" do
      mare = Neighborhood.find_by_name(Neighborhood::Names::MARE)
      tepa = Neighborhood.find_by_name(Neighborhood::Names::TEPALCINGO)
      if mare.id
        mare.name
      elsif tepa.id
        tepalcingo.name
      end
    end

    column "blocked"

    column "created_at"
    column "updated_at"

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
