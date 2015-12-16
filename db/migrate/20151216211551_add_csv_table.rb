class AddCsvTable < ActiveRecord::Migration
  def change
    create_table :csvs do |t|
      t.integer :user_id
      t.integer :location_id

      t.datetime :parsed_at
      t.datetime :verified_at

      t.attachment :csv

      t.timestamps
    end

    add_column :reports,     :csv_id, :integer
    add_column :visits,      :csv_id, :integer
    add_column :inspections, :csv_id, :integer
    add_column :csv_errors,  :csv_id, :integer
  end
end
