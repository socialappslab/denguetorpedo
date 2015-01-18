class AddHealthReportToLocationStatus < ActiveRecord::Migration
  def change
    add_column :location_statuses, :health_report, :string
  end
end
