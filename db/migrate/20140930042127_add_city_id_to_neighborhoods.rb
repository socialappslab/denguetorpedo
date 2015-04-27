# -*- encoding : utf-8 -*-
class AddCityIdToNeighborhoods < ActiveRecord::Migration
  def change
    add_column :neighborhoods, :city_id, :integer
  end
end
