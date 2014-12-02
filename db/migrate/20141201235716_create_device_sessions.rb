class CreateDeviceSessions < ActiveRecord::Migration
  def up
    create_table :device_sessions do |t|
      t.integer :user_id
      t.string  :token
      t.string  :device_name
      t.string  :device_model
      t.timestamps
    end
  end

  def down
    drop_table :device_sessions
  end
end
