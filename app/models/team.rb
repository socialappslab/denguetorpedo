# encoding: UTF-8

class Team < ActiveRecord::Base
  attr_accessible :name, :profile_photo, :neighborhood_id

  has_attached_file :profile_photo, :styles => {:small => "60x60>", :medium => "150x150>" , :large => "225x225>"}

  has_many :team_memberships
  has_many :users, :through => :team_memberships

  #----------------------------------------------------------------------------

  validates :name, :presence => true
  validates :name, :length => { :minimum => 2 }
  validates :neighborhood_id, :presence => true

  #----------------------------------------------------------------------------

  def total_points
    self.users.sum(:total_points)
  end

  #----------------------------------------------------------------------------

  def total_reports
    sum = 0
    self.users.each do |user|
      sum += user.reports.count
    end

    return sum
  end

  #----------------------------------------------------------------------------

end
