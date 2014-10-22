class AddCsvReportIdToReports < ActiveRecord::Migration
  def change
    add_column :reports, :csv_report_id, :integer
    remove_column :csv_reports, :report_id
  end
end
