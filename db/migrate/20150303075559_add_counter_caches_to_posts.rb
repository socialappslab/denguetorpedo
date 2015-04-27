# -*- encoding : utf-8 -*-
class AddCounterCachesToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :likes_count, :integer, :default => 0

    Post.reset_column_information
    Post.find_each do |p|
      p.update_column(:likes_count, p.likes.count)
    end
  end
end
