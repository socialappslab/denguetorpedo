class AddFeedTypeCdToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :feed_type_cd, :integer
  end
end
