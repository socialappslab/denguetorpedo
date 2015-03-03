class AddLikesCountToReports < ActiveRecord::Migration
  def change
    add_column :reports, :likes_count, :integer, :default => 0

    Report.reset_column_information
    Report.find_each do |r|
      r.update_column(:likes_count, r.likes.count)
    end
  end
end
