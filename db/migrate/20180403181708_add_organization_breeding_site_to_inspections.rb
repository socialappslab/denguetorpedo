class AddOrganizationBreedingSiteToInspections < ActiveRecord::Migration
  def change
    add_reference :inspections, :organization_breeding_site, index: false
  end
end
