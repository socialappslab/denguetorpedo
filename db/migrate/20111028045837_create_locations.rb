# -*- encoding : utf-8 -*-
class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :neighborhood
      t.string :address
      t.float :latitude
      t.float :longitude
      t.boolean :gmaps

      t.timestamps
    end
  end
end
