# encoding: UTF-8

class Team < ActiveRecord::Base
  attr_accessible :name

  has_attached_file :profile_photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}

  has_many :team_memberships
  has_many :users, :through => :team_memberships
end
