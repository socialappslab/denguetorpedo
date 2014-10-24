class CleanupTables < ActiveRecord::Migration
  def up
    remove_column :reports, :elimination_type
    remove_column :reports, :elimination_method
    remove_column :reports, :reporter_name
    remove_column :reports, :eliminator_name

    remove_column :locations, :formatted_address
    remove_column :locations, :gmaps

  end

  def down
    add_column :reports, :elimination_type, :string
    add_column :reports, :elimination_method, :string
    add_column :reports, :reporter_name, :string
    add_column :reports, :eliminator_name, :string

    add_column :locations, :formatted_address, :string
    add_column :locations, :gmaps, :string
  end
end
