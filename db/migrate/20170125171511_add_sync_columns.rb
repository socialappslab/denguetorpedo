class AddSyncColumns < ActiveRecord::Migration
  def change
    add_column :posts, :last_synced_at, :datetime
    add_column :posts, :last_sync_seq,  :integer

    add_column :visits, :last_synced_at, :datetime
    add_column :visits, :last_sync_seq,  :integer

    add_column :locations, :last_synced_at, :datetime
    add_column :locations, :last_sync_seq,  :integer

    add_column :inspections, :last_synced_at, :datetime
    add_column :inspections, :last_sync_seq,  :integer
  end
end
