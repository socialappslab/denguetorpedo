# -*- encoding : utf-8 -*-
class DeprecateColumnsInNeighborhoods < ActiveRecord::Migration
  def up
    remove_column :neighborhoods, :country_string_id
    remove_column :neighborhoods, :state_string_id
    remove_column :neighborhoods, :city
  end

  def down
    add_column :neighborhoods, :city, :string
    add_column :neighborhoods, :state_string_id, :string
    add_column :neighborhoods, :country_string_id, :string
  end
end
