# -*- encoding : utf-8 -*-
class CreateBreedingSites < ActiveRecord::Migration
  def up
    create_table "breeding_sites", :force => true do |t|
      t.string  :description_in_pt
      t.string  :description_in_es
      t.integer :points
    end
  end

  def down
    drop_table :breeding_sites
  end
end
