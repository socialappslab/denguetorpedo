class AddCompletedAtToInspection < ActiveRecord::Migration
  def change
    add_column :inspections, :completed_at, :datetime
  end
end
