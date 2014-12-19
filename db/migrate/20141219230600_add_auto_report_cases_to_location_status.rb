class AddAutoReportCasesToLocationStatus < ActiveRecord::Migration
  def change
    add_column :location_statuses, :dengue, :boolean
    add_column :location_statuses, :chikungunya, :boolean
  end
end
