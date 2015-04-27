# -*- encoding : utf-8 -*-
class PopulateTeamIdColumnForPrizes < ActiveRecord::Migration
  def up
    Prize.find_each do |p|
      house = p.user.house
      if house.nil?
        puts "[!] Couldn't find house for prize #{p.prize_name} (id: #{p.id})"
        next
      end

      puts "[ok] Found house #{house.name} for prize #{p.prize_name} (id: #{p.id})..."
      team  = Team.find_by_name(house.name)
      puts "[ok] Found corresponding team #{team.name}..."

      p.update_attribute(:team_id, team.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
