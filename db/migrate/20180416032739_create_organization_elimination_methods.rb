class CreateOrganizationEliminationMethods < ActiveRecord::Migration
  def change
    create_table :organization_elimination_methods do |t|
      t.integer :elimination_method_id
      t.integer :organization_id
      t.string :code
      t.string :description
    end
  end
end
