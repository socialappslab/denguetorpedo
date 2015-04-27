# -*- encoding : utf-8 -*-
class AddBlockedToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :blocked, :boolean
  end
end
