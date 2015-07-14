class AddCsvErrors < ActiveRecord::Migration
  def up
    create_table :csv_errors do |t|
      t.integer :csv_report_id
      t.integer :error_type

      t.timestamps
    end
  end

  def down
    drop_table :csv_errors
  end
end
