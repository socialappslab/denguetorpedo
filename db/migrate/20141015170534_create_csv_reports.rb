# -*- encoding : utf-8 -*-
class CreateCsvReports < ActiveRecord::Migration
  def up
    create_table :csv_reports do |t|
      t.text    :parsed_content
      t.integer :report_id
      t.timestamps
    end

    add_attachment :csv_reports, :csv
  end

  def down
    remove_attachment :csv_reports, :csv
    drop_table :csv_reports
  end
end
