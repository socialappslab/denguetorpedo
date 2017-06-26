class CreateCityBlocksAndDistricts < ActiveRecord::Migration
  def change
    create_table :city_blocks do |t|
      t.string  :name
      t.integer :neighborhood_id
      t.integer :district_id
      t.integer :city_id
    end

    add_column :locations, :city_block_id, :integer
    add_index :locations, :city_block_id

    add_column :locations, :city_id, :integer
    add_index :locations,  :city_id

    # This allows us to classify the type of location (house, school, etc).
    add_column :locations, :location_type, :string

    create_table :districts do |t|
      t.string  :name
      t.integer :city_id
    end

    add_column :neighborhoods, :district_id, :integer
    add_index  :neighborhoods, :district_id
  end
end
