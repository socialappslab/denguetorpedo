# -*- encoding : utf-8 -*-
class AddNameToHouse < ActiveRecord::Migration
  def change
    add_column :houses, :name, :string
  end
end
