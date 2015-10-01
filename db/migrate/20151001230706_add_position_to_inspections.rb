class AddPositionToInspections < ActiveRecord::Migration
  def change
    add_column :inspections, :position, :integer, :default => 0
  end
end
