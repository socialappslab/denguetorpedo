class RenameLocationStatusToVisit < ActiveRecord::Migration
  def up
    rename_table :location_statuses, :visits
  end

  def down
    rename_table :visits, :location_statuses
  end
end
