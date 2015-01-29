class RemoveIdentifiedAtCleanedAtStatusColumnsFromVisit < ActiveRecord::Migration
  def up
    remove_column :visits, :identified_at
    remove_column :visits, :cleaned_at
  end

  def down
    add_column :visits, :cleaned_at,    :datetime
    add_column :visits, :identified_at, :datetime
  end
end
