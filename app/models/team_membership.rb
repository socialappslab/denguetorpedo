# -*- encoding : utf-8 -*-

class TeamMembership < ActiveRecord::Base
  attr_accessible :user_id, :team_id, :verified

  belongs_to :user
  belongs_to :team
end
