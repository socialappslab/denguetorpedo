class AddFieldIdentifierToReports < ActiveRecord::Migration
  def change
    add_column :reports, :field_identifier, :string
  end
end
