# -*- encoding : utf-8 -*-
class AddTotalPointsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :total_points, :integer, :default => 0
  end
end
