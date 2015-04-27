# -*- encoding : utf-8 -*-
class CreateEliminationMethods < ActiveRecord::Migration
  def change
    create_table :elimination_methods do |t|
    	t.string :method
    	t.integer :points
      t.timestamps
    end
  end
end
