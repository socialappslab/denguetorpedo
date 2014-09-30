class CreateUserNotifications < ActiveRecord::Migration
  def up
    create_table :user_notifications do |t|
      t.integer :user_id
      t.integer :notification_type
      t.boolean :viewed

      t.timestamps
    end
  end

  def down
    drop_table :user_notifications
  end
end
