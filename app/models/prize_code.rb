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

  before_validation :generate_activation_code

  # TODO: more stuff
  # TODO @dman7: Deprecating this since we don't use Twilio.
  # def self.send_no(phone_number)
  # 	@account_sid = 'AC696e86d23ebba91cbf65f1383cf63e7d'
  #   @auth_token = 'a49ee186176ead11c760fd77aeaeb26c'
  #   @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  #   @account = @client.account
  #   body = "Not a valid code." # Portuguese PLS
  #   @account.sms.messages.create(:from => '+15109854798', :to => phone_number , :body  => body)
  # end
  #
  # def send_yes(phone_number)
  # 	@account_sid = 'AC696e86d23ebba91cbf65f1383cf63e7d'
  #   @auth_token = 'a49ee186176ead11c760fd77aeaeb26c'
  #   @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  #   @account = @client.account
  #   body = "Valid code!"
  #   @account.sms.messages.create(:from => '+15109854798', :to => phone_number , :body  => body)
  #   self.destoy
  # end

  def expired?
    return self.created_at + 3600 * 24 * 7 < Time.new
  end

  def expire_date
    self.created_at + 3600 * 24 * 7
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
