# -*- encoding : utf-8 -*-
class AddHouseIdToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.references :house
    end
  end
end
