class AddLocationToCsvReports < ActiveRecord::Migration
  def change
    add_column :csv_reports, :location_id, :integer
  end
end
