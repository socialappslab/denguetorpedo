class AddColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :breeding_site_id, :integer
    add_column :reports, :elimination_method_id, :integer
  end
end
