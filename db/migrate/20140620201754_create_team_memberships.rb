# -*- encoding : utf-8 -*-
class CreateTeamMemberships < ActiveRecord::Migration
  def up
    create_table :team_memberships do |t|
      t.integer :user_id
      t.integer :team_id
      t.boolean :verified

      t.timestamps
    end
  end

  def down
    drop_table :team_memberships
  end
end
