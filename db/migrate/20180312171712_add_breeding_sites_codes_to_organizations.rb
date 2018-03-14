class AddBreedingSitesCodesToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :breeding_sites_codes, :jsonb
  end
end
