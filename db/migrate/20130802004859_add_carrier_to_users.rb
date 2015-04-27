# -*- encoding : utf-8 -*-
class AddCarrierToUsers < ActiveRecord::Migration
  def change
    add_column :users, :carrier, :string, :default => ""
  end
end
