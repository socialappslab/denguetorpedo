class UpdateVisitsTable < ActiveRecord::Migration
  def up
    add_column :visits, :parent_visit_id, :integer
  end

  def down
    remove_column :visits, :parent_visit_id
  end
end
