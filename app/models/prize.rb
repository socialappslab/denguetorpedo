# encoding: utf-8

class Prize < ActiveRecord::Base
  #----------------------------------------------------------------------------

  attr_accessible :cost, :neighborhood_id, :description, :expire_on, :prize_name, :redemption_directions, :stock, :user_id, :prize_photo, :community_prize, :self_prize, :is_badge, :user, :prazo

  #----------------------------------------------------------------------------

  belongs_to :user
  has_many :prize_codes, :dependent => :destroy
  has_attached_file :prize_photo, :default_url => 'home_images/logo.png', :styles => { :small => "60x60>", :large => "150x150>" }#, :storage => STORAGE, :s3_credentials => S3_CREDENTIALS

  #----------------------------------------------------------------------------

  validates :cost, :presence => true
  validates :description, :presence => true
  validates :prize_name, :presence => true
  validates :stock, :presence => true
  validates :user, :presence => true
  belongs_to :neighborhood

  #----------------------------------------------------------------------------

  def expired?
    return self.stock == 0 || (self.expire_on.present? && self.expire_on < Time.now)
  end

  def available?
    return !self.expired?
  end

  #----------------------------------------------------------------------------

  def sponsor_name
    return self.user.house.name
  end

  #----------------------------------------------------------------------------


end
