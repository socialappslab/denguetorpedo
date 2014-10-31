class AddColumnToReports < ActiveRecord::Migration
  def change
    add_column :reports, :csv_uuid, :string
  end
end
