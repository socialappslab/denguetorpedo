class AddPreviousSimilarInspectionIdToInspections < ActiveRecord::Migration
  def change
    add_column :inspections, :previous_similar_inspection_id, :integer
  end
end
