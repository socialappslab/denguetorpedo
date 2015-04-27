# -*- encoding : utf-8 -*-
class AddCoordinatorToNeighborhood < ActiveRecord::Migration
  def change
    add_column :neighborhoods, :coordinator_id, :integer
  end
end
