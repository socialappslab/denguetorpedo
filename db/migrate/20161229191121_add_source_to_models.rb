class AddSourceToModels < ActiveRecord::Migration
  def change
    add_column :reports,     :source, :string
    add_column :visits,      :source, :string
    add_column :locations,   :source, :string
    add_column :inspections, :source, :string
  end
end
