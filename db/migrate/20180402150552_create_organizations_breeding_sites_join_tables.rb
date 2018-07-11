class CreateOrganizationsBreedingSitesJoinTables < ActiveRecord::Migration
  def change
    create_table :organizations_breeding_sites do |t|
      t.integer :organization_id
      t.integer :breeding_site_id
      t.text :description, :default => ""
      t.string :code
    end
  end
end
