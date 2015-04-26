# -*- encoding : utf-8 -*-
# This migration will copy all houses data over to teams.
#

class MoveHousesToTeams < ActiveRecord::Migration
  def up
    # Copy the house attributes over to the teams attribute.
    default_neighborhood = Neighborhood.find_by_name("Maré")
    House.find_each do |h|
      team                 = Team.new
      team.name            = h.name
      team.neighborhood_id = h.neighborhood_id || default_neighborhood.id
      team.profile_photo   = h.profile_photo
      team.created_at      = h.created_at
      team.save!

      # Now add all the users in the house to the teams.
      h.members.each do |user|
        TeamMembership.create(:user_id => user.id, :team_id => team.id)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
