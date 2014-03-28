class AddNeighborhoodIdToPrizes < ActiveRecord::Migration
  def change
    add_column :prizes, :neighborhood_id, :integer
  end
end
