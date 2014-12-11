class RemoveStatusFromReports < ActiveRecord::Migration
  def up
    remove_column :reports, :status
  end

  def down
    add_column :reports, :status, :integer
  end
end
