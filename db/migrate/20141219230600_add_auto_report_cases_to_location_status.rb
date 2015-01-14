class AddAutoReportCasesToLocationStatus < ActiveRecord::Migration
  def change
    add_column :location_statuses, :dengue_count, :integer
    add_column :location_statuses, :chik_count,   :integer
  end
end
