class AddSyncedToReports < ActiveRecord::Migration
  def change
    add_column :reports, :last_synced_at, :datetime
    add_column :reports, :last_sync_seq,  :integer
  end
end
