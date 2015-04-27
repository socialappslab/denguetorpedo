# -*- encoding : utf-8 -*-
class AddNeighborhoodIdToHouses < ActiveRecord::Migration
  def change
    add_column :houses, :neighborhood_id, :integer
  end
end
