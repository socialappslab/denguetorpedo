class AddVerifiedParsedColumnsToCsvReports < ActiveRecord::Migration
  def change
    add_column :csv_reports, :parsed_at,   :datetime
    add_column :csv_reports, :verified_at, :datetime
  end
end
