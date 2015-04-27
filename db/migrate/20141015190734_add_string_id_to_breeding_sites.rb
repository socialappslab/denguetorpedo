# -*- encoding : utf-8 -*-
class AddStringIdToBreedingSites < ActiveRecord::Migration
  def change
    add_column :breeding_sites, :string_id, :string
  end
end
