# -*- encoding : utf-8 -*-
class AddEliminationTypeToEliminationMethods < ActiveRecord::Migration
  def change
  	add_column :elimination_methods, :elimination_type_id, :integer, references: :elimination_type
  end
end
