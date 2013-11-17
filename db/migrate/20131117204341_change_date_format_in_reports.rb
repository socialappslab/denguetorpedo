class ChangeDateFormatInReports < ActiveRecord::Migration
  def up
  	change_column :reports, :completed_at, :datetime
  	change_column :reports, :credited_at, :datetime
  end

  def down
  	change_column :reports, :completed_at, :timestamp
  	change_column :reports, :credited_at, :timestamp
  end
end
