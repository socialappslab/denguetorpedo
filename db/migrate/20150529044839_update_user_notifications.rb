class UpdateUserNotifications < ActiveRecord::Migration
  def up
    remove_column :user_notifications, :created_at
    remove_column :user_notifications, :updated_at
    remove_column :user_notifications, :viewed

    change_column :user_notifications, :notification_type, :string
    add_column    :user_notifications, :notification_id, :integer
    add_column    :user_notifications, :notified_at, :datetime
    add_column    :user_notifications, :seen_at, :datetime
    add_column    :user_notifications, :medium, :integer

    add_index :user_notifications, :seen_at
  end

  def down
    remove_index :user_notifications, :seen_at

    remove_column :user_notifications, :medium
    remove_column :user_notifications, :seen_at
    remove_column :user_notifications, :notified_at
    remove_column :user_notifications, :notification_id
    change_column :user_notifications, :notification_type, :integer

    add_column    :user_notifications, :viewed, :boolean
    add_column    :user_notifications, :updated_at, :datetime
    add_column    :user_notifications, :created_at, :datetime
  end
end
