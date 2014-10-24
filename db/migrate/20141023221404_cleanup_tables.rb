class CleanupTables < ActiveRecord::Migration
  def up
    remove_column :reports, :nation
    remove_column :reports, :state
    remove_column :reports, :city
    remove_column :reports, :address
    remove_column :reports, :neighborhood
    remove_column :reports, :status_cd
    remove_column :reports, :feed_type_cd
    remove_column :reports, :elimination_type
    remove_column :reports, :elimination_method
    remove_column :reports, :reporter_name
    remove_column :reports, :eliminator_name

    remove_column :locations, :formatted_address
    remove_column :locations, :gmaps

  end

  def down
    add_column :reports, :nation, :string
    add_column :reports, :state, :string
    add_column :reports, :city, :string
    add_column :reports, :address, :string
    add_column :reports, :neighborhood, :string
    add_column :reports, :status_cd, :integer
    add_column :reports, :feed_type_cd, :integer
    add_column :reports, :elimination_type, :string
    add_column :reports, :elimination_method, :string
    add_column :reports, :reporter_name, :string
    add_column :reports, :eliminator_name, :string

    add_column :locations, :formatted_address, :string
    add_column :locations, :gmaps, :string
  end
end
