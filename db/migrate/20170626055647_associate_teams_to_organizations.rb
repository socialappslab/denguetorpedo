class AssociateTeamsToOrganizations < ActiveRecord::Migration
  def change
    add_column :teams, :organization_id, :integer
    add_index  :teams, :organization_id
  end
end
