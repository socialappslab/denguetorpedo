class AddCreditedAtToReports < ActiveRecord::Migration
  def change
    add_column :reports, :credited_at, :timestamp
  end
end
