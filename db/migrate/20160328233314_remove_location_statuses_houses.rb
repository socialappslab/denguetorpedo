class RemoveLocationStatusesHouses < ActiveRecord::Migration
  def change
    drop_table :location_statuses
    drop_table :badges
    drop_table :buy_ins
    drop_table :ckeditor_assets
    drop_table :contacts
    drop_table :feedbacks
    drop_table :feeds
  end
end
