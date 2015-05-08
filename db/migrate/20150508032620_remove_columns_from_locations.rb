class RemoveColumnsFromLocations < ActiveRecord::Migration
  def up
    remove_column :locations, :nation
    remove_column :locations, :state
    remove_column :locations, :city
    remove_column :locations, :neighborhood
    remove_column :locations, :cleaned
  end

  def down
  end
end
