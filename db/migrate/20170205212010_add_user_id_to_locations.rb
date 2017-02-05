class AddUserIdToLocations < ActiveRecord::Migration
  def change
    create_table :user_locations do |t|
      t.integer  :user_id
      t.integer  :location_id
      t.datetime :assigned_at
      t.string   :source

      t.timestamps
    end

    add_index :user_locations, [:user_id, :location_id], :unique => true
  end
end
