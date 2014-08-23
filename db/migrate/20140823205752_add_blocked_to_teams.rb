class AddBlockedToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :blocked, :boolean
  end
end
