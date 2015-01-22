class AddTimeColumnsToLocationStatuses < ActiveRecord::Migration
  def change
    add_column :location_statuses, :identification_type, :integer
    add_column :location_statuses, :identified_at, :datetime
    add_column :location_statuses, :cleaned_at, :datetime
  end
end
