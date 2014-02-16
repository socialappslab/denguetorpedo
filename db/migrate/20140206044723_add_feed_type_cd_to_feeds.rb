class AddFeedTypeCdToFeeds < ActiveRecord::Migration
  def change
    unless column_exists? :feeds, :feed_type_cd
      add_column :feeds, :feed_type_cd, :integer
    end
  end
end
