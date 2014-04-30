class RemoveStatusCdFromReports < ActiveRecord::Migration
  def up
    remove_column :reports, :status_cd
  end

  def down
    add_column :reports, :status_cd, :integer
  end
end
