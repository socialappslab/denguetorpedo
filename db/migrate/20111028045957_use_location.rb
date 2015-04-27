# -*- encoding : utf-8 -*-
class UseLocation < ActiveRecord::Migration
  def up
    add_column :reports, :location_id, :integer
    add_column :houses, :location_id, :integer
  end

  def down
    remove_column :reports, :location_id
    remove_column :houses, :location_id
  end
end
