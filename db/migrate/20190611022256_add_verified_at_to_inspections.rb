class AddVerifiedAtToInspections < ActiveRecord::Migration
  def change
    add_column :inspections, :verified_at, :datetime
  end
end
