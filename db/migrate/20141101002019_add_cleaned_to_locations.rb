# -*- encoding : utf-8 -*-
class AddCleanedToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :cleaned, :boolean, :default => false
  end
end
