# -*- encoding : utf-8 -*-
class CreateEliminationTypes < ActiveRecord::Migration
  def change
    create_table :elimination_types do |t|
    	t.string :type
    	t.integer :points
      t.timestamps
    end
  end
end
