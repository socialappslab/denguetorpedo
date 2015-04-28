# -*- encoding : utf-8 -*-

class Team < ActiveRecord::Base
  attr_accessible :name, :blocked, :profile_photo, :neighborhood_id, :points

  has_attached_file :profile_photo, :styles => {
    :small => ["150x150>", :jpg],
    :large => ["300x300>", :jpg]
  }, :convert_options => { :small => "-quality 75 -strip", :large => "-quality 75 -strip" }
  validates_attachment :profile_photo, content_type: { content_type: /\Aimage\/.*\Z/ }

  has_many :team_memberships, :dependent => :destroy
  has_many :users, :through => :team_memberships
  has_many :prizes, :dependent => :destroy
  belongs_to :neighborhood

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

  def descriptive_name
    return I18n.t("activerecord.models.team", :count => 1) + " " + self.name
  end

  #----------------------------------------------------------------------------

  def picture
    return "teams/default.png" if self.profile_photo_file_name.nil?
    return self.profile_photo.url(:small)
  end

  #----------------------------------------------------------------------------

end
