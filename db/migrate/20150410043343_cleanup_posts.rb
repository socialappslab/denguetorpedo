# -*- encoding : utf-8 -*-
class CleanupPosts < ActiveRecord::Migration
  def up
    remove_column :posts, :type_cd
    remove_column :posts, :parent_id
    remove_column :posts, :lft
    remove_column :posts, :rgt
    remove_column :posts, :wall_id
    remove_column :posts, :wall_type
  end

  def down
    add_column :posts, :wall_type
    add_column :posts, :wall_id
    add_column :posts, :rgt
    add_column :posts, :lft
    add_column :posts, :parent_id
    add_column :posts, :type_cd
  end
end
