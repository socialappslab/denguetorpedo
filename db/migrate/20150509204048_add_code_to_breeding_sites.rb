class AddCodeToBreedingSites < ActiveRecord::Migration
  def change
    add_column :breeding_sites, :code, :string
  end
end
