class RenameTypeToNameInEliminationTypes < ActiveRecord::Migration
  def up
  	rename_column :elimination_types, :type, :name
  end

  def down
  	rename_column :elimination_types, :name, :type
  end
end
