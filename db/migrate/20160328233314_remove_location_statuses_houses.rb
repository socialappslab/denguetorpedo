class RemoveLocationStatusesHouses < ActiveRecord::Migration
  def change
    drop_table :contacts
    drop_table :feedbacks
    drop_table :feeds
  end
end
