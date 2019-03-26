class AddFieldsToCsvs < ActiveRecord::Migration
  def change
    add_column :csvs, :source, :text
    add_column :csvs, :contains_photo_urls, :boolean
    add_column :csvs, :username_per_inspections, :boolean
  end
end
