# -*- encoding : utf-8 -*-
# A PrizeCode instance is a coupon for a prize.
# It allows the user to redeem the prize by using the
# code associated with the coupon.
#
# a) We say a coupon is *claimed* if a user has given up points to
#    receive the coupon.
# b) We say a coupon is *redeemed* if the user has claimed it and redeemed
#    it for the prize.
#
class PrizeCode < ActiveRecord::Base
  #----------------------------------------------------------------------------

  attr_accessible :code, :expire_by, :prize_id, :user_id, :redeemed, :expired

  #----------------------------------------------------------------------------

  belongs_to :user
  belongs_to :prize

  #----------------------------------------------------------------------------

  before_validation :generate_activation_code

  validates :code, :presence => true, :uniqueness => { :scope => :prize_id, :message => "We need a unique prize code for each user for a given prize"}
  validates :user, :presence => true
  validates :prize, :presence => true

  #----------------------------------------------------------------------------

  EXPIRY = 7.days

  #----------------------------------------------------------------------------

  def is_redeemed?
    return self.redeemed
  end

  def redeemed?
    return self.is_redeemed?
  end

  def expired?
    return (self.created_at < EXPIRY.ago) || self.prize.expired?
  end

  def available?
    return !self.expired?
  end

  def expire_date
    self.created_at + EXPIRY
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def generate_activation_code(size = 12)
    charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
    self.code = (0...size).map{ charset.to_a[rand(charset.size)] }.join
  end

  #----------------------------------------------------------------------------
end
