class AddStatusColumnToReports < ActiveRecord::Migration
  def change
    add_column :reports, :status, :string
  end
end
