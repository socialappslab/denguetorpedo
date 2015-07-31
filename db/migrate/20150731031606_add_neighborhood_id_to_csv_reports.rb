class AddNeighborhoodIdToCsvReports < ActiveRecord::Migration
  def change
    add_column :csv_reports, :neighborhood_id, :integer
  end
end
