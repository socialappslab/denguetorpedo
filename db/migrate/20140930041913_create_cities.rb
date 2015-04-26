# -*- encoding : utf-8 -*-
class CreateCities < ActiveRecord::Migration
  def up
    create_table :cities do |t|
      t.string :name
      t.string :state
      t.string :state_code
      t.integer :country_id
    end
  end

  def down
  end
end
