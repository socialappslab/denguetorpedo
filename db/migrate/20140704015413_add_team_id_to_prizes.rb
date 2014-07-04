class AddTeamIdToPrizes < ActiveRecord::Migration
  def change
    add_column :prizes, :team_id, :integer
  end
end
