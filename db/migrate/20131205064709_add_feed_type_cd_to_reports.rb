class AddFeedTypeCdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :integer, :feed_type_cd
  end
end
