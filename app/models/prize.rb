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

  def give_badge(user_id)
    @user = User.find(user_id)
    Badge.create({:user_id => user_id, :prize_id => self.id})
  end

  #----------------------------------------------------------------------------

  def generate_prize_code(user_id)
    prize_code = PrizeCode.create({:user_id => user_id, :prize_id => self.id})
    user = User.find_by_id(user_id)
    if user
      user.points = user.points - self.cost
      user.save
      self.decrease_stock(1)
      self.save
    end
    return prize_code
  end

  #----------------------------------------------------------------------------

  def in_stock
    return true if self.stock < 0 or self.stock > 0
    return false
  end

  #----------------------------------------------------------------------------

  def decrease_stock(n = 1)
    if stock > 0
      temp = self.stock
      self.stock = stock - n
      if self.stock < 0
        self.stock = temp
        return false
      end
    end
    return true
  end

  #----------------------------------------------------------------------------

  def sponsor_name
    return self.user.house.name
  end

  #----------------------------------------------------------------------------

  def expired?
    if self.stock == 0 or (self.expire_on and self.expire_on <= Time.now)
      1
    else
      0
    end
  end

  def available?
    not self.expired?
  end

end
