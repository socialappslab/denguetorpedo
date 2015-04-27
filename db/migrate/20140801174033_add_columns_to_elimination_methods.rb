# -*- encoding : utf-8 -*-
class AddColumnsToEliminationMethods < ActiveRecord::Migration
  def change
    add_column :elimination_methods, :breeding_site_id,  :integer
    add_column :elimination_methods, :description_in_pt, :string
    add_column :elimination_methods, :description_in_es, :string
  end
end
