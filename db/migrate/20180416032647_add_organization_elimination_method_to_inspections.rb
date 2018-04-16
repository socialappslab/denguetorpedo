class AddOrganizationEliminationMethodToInspections < ActiveRecord::Migration
  def change
    add_reference :inspections, :organization_elimination_method, index: false
  end
end
