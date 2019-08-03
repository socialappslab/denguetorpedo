class AddLikesCountToInspections < ActiveRecord::Migration
  def change
    add_column :inspections, :likes_count, :integer, default: 0

    Inspection.reset_column_information
    Inspection.find_each do |r|
      r.update_column(:likes_count, r.likes.count)
    end
  end
end
