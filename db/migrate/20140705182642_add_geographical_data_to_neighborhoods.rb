# -*- encoding : utf-8 -*-
class AddGeographicalDataToNeighborhoods < ActiveRecord::Migration
  def up
    add_column :neighborhoods, :country_string_id, :string
    add_column :neighborhoods, :state_string_id,   :string
    add_column :neighborhoods, :city,              :string

    remove_column :neighborhoods, :coordinator_id
  end

  def down
    add_column :neighborhoods, :coordinator_id, :integer

    remove_column :neighborhoods, :country_string_id
    remove_column :neighborhoods, :state_string_id
    remove_column :neighborhoods, :city
  end
end
