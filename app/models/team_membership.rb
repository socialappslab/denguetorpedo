# encoding: UTF-8

class TeamMembership < ActiveRecord::Base
  attr_accessible :user_id, :team_id
end
