class UpdateVisitsAndReports < ActiveRecord::Migration
  def up
    # Update the reports table.
    remove_column :reports, :visit_id

    # Update the visits table.
    remove_column :visits, :identification_type
    remove_column :visits, :visit_type
    remove_column :visits, :created_at
    remove_column :visits, :updated_at
  end

  def down
    add_column :visits, :updated_at, :datetime
    add_column :visits, :created_at, :datetime
    add_column :visits, :visit_type, :integer
    add_column :visits, :identification_type, :integer

    add_column :reports, :visit_id, :integer
  end
end
