class AddNeighborhoodIdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :neighborhood_id, :integer
  end
end
