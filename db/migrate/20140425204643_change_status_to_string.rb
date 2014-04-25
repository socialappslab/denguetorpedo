class ChangeStatusToString < ActiveRecord::Migration
  def change
    remove_column :reports, :status, :integer
    add_column :reports, :status, :string
  end
end
