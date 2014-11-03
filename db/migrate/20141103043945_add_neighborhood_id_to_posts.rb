class AddNeighborhoodIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :neighborhood_id, :integer
  end
end
