class RemoveStatusCdFromReports < ActiveRecord::Migration
  def change
    remove_column :reports, :status_cd
  end
end
