class AddDefaultValuesToFieldsOfCsvs < ActiveRecord::Migration
  def change
    change_column :csvs, :source, :text
    change_column :csvs, :contains_photo_urls, :boolean, :default => false
    change_column :csvs, :username_per_inspections, :boolean, :default => false
  end
end
