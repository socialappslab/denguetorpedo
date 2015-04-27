# -*- encoding : utf-8 -*-
class AddFormattedAddressToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :formatted_address, :string
  end
end
