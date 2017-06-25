class RemoveColumnsFromLocations < ActiveRecord::Migration
  def up
    remove_column :locations, :neighborhood
    remove_column :locations, :cleaned
  end

  def down
  end
end
