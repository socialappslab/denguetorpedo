class AddPolygonToCityBlocks < ActiveRecord::Migration
  def change
    add_column :city_blocks, :polygon, :text
  end
end
