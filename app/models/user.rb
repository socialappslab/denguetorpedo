# encoding: utf-8

class User < ActiveRecord::Base
  #----------------------------------------------------------------------------

  ROLES = ["morador", "logista", "visitante"]
  MIN_PHONE_LENGTH = 7
  PHONE_NUMBER_PLACEHOLDER = "000000000000"

  module Types
    ADMIN       = "admin"
    COORDINATOR = "coordenador"
    SPONSOR     = "lojista"
    VERIFIER    = "verificador"
    RESIDENT    = "morador"
    VISITOR     = "visitante"
  end

  has_secure_password
  has_attached_file :profile_photo, :styles => { :small => "60x60>", :large => "150x150>" }, :default_url => 'default_images/profile_default_image.png'#, :storage => STORAGE, :s3_credentials => S3_CREDENTIALS

  #----------------------------------------------------------------------------
  # Validators
  #-----------

  validates :first_name, presence: true, :length => { :minimum => 2, :maximum => 16 }
  validates :last_name, presence: true, :length => { :minimum => 2, :maximum => 16 }
  validates :password, :length => { :minimum => 4}, :if => "id.nil? || password"
  validates :points, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates :total_points, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0}
  validates :email, :format => { :with => EMAIL_REGEX }, :allow_nil => true
  validates :email, :uniqueness => true, :unless => "email.nil?"
  validates :house_id, presence: { on: :special_create, if: :not_visitor }
  # validates_length_of :phone_number, :minimum => 12, :message => "Número de celular invalido.  O formato correto é 0219xxxxxxxx", :unless => Proc.new { |u| u.new_record? }
  validates :neighborhood_id, :presence => true, :unless => Proc.new { |u| u.new_record? }
  #----------------------------------------------------------------------------


  #----------------------------------------------------------------------------
  # Filters
  #--------
  before_create { generate_token(:auth_token) }

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  # TODO: reports should include both eliminator_id and reporter_id.
  has_many :created_reports,    :class_name => "Report", :foreign_key => "reporter_id",   :dependent => :nullify
  has_many :eliminated_reports, :class_name => "Report", :foreign_key => "eliminator_id", :dependent => :nullify
  has_many :verified_reports,   :class_name => "Report", :foreign_key => "verifier_id",   :dependent => :nullify

  has_many :feeds, :dependent => :destroy
  has_many :posts, :dependent => :destroy
  has_many :prize_codes, :dependent => :destroy
  has_many :badges
  has_many :prizes, :dependent => :destroy

  has_one :recruiter_relationships, :class_name => "Recruitment", :foreign_key => "recruitee_id"
  has_one :recruiter, :through => :recruiter_relationships, :source => :recruiter
  has_many :recruitee_relationships, :class_name => "Recruitment", :foreign_key => "recruiter_id"
  has_many :recruitees, :through => :recruitee_relationships, :source => :recruitee
  belongs_to :house
  belongs_to :neighborhood

  scope :residents, where("role = 'morador' OR role = 'admin' OR role = 'coordenador'")

  has_many :team_memberships
  has_many :teams, :through => :team_memberships

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :house, :allow_destroy => true
  attr_accessible :house_attributes
  attr_accessible :first_name, :neighborhood_id, :last_name, :middle_name, :nickname, :email, :password, :password_confirmation, :auth_token, :phone_number, :phone_number_confirmation, :profile_photo, :display, :is_verifier, :is_fully_registered, :is_health_agent, :role, :gender, :is_blocked, :house_id, :carrier, :prepaid

  #----------------------------------------------------------------------------

  # TODO: This is still not ideal but Rails doesn't have a clean way to load
  # an association on multiple foreign_keys. Perhaps calling created_reports
  # and eliminated_reports separately here would be faster?
  def reports
    Report.where("reporter_id = ? OR eliminator_id = ?", self.id, self.id).order("updated_at DESC")
  end

  #----------------------------------------------------------------------------

  def can_manage_other_users?
    return [Types::ADMIN, Types::COORDINATOR].include?(self.role)
  end

  def location
    house && house.location
  end


  def check_house(house_attributes)
    if house = House.find_by_name(house_attributes[:name])
      return true
    end
    return false
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def nearby_reports(n = 10)
    if house.nil? or house.location.nil?
      nil
    else
      lat = house.location.latitude
      lon = house.location.longitude
      dist_str = "((locations.latitude - #{lat}) * (locations.latitude - #{lat}) + (locations.longitude - #{lon}) * (locations.longitude - #{lon}))"
      Report.joins(:location).order(dist_str).limit(n)
    end
  end

  def neighbors(n = 10)
    if house.nil? or house.location.nil?
      nil
    else
      lat = house.location.latitude
      lon = house.location.longitude
      dist_str = "((locations.latitude - #{lat}) * (locations.latitude - #{lat}) + (locations.longitude - #{lon}) * (locations.longitude - #{lon}))"
      User.joins(:house => :location).where("houses.id != ?", house.id).order(dist_str).limit(n)
    end
  end

  #----------------------------------------------------------------------------
  # In order to generate a coupon for a prize, the following must happen:
  # a) Prize stock must decrease by 1, and
  # b) User's total points must decrease by the right amount.

  def generate_coupon_for_prize(prize)
    return nil if self.total_points < prize.cost || prize.expired?

    unless prize.is_badge?
      prize.update_attribute(:stock, [0, prize.stock - 1].max)
      self.update_attribute(:total_points, self.total_points - prize.cost)

      return PrizeCode.create(:user_id => self.id, :prize_id => prize.id)
    end
  end

  #----------------------------------------------------------------------------

  def display_name_options
    options = [
      [self.first_name + " " + self.last_name,"firstlast"],
      [self.first_name,"first"]
    ]

    if self.nickname.present?
      options += [
        [self.nickname, "nickname"],
        [self.first_name + " " + self.last_name + " (" + self.nickname + ")","firstlastnickname"]
      ]
    end

    return options
  end

  #----------------------------------------------------------------------------

  def display_name
    if self.display == "firstmiddlelast"
      if self.middle_name
        display_name = self.first_name + " " + self.middle_name + " " + self.last_name
      else
        display_name = self.first_name + " " + self.last_name
      end

    elsif self.display == "firstlast"
      display_name = self.first_name + " " + self.last_name
    elsif self.display == "first"
      display_name = self.first_name
    elsif self.display == "nickname"
      display_name = self.nickname
    else
      if nickname
        display_name = self.first_name + " " + self.last_name + " (" + self.nickname + ")"
      else
        display_name = self.first_name + " " + self.last_name
      end

    end

    return display_name
  end

  #----------------------------------------------------------------------------

  def shorter_display_name
    if self.display == "firstmiddlelast"
      display_name = self.first_name + " " + self.middle_name + " " + self.last_name
    elsif self.display == "firstlast"
      display_name = self.first_name + " " + self.last_name
    elsif self.display == "first"
      display_name = self.first_name
    elsif self.display == "nicname"
      display_name = self.nickname
    else
      display_name = self.first_name + " " + self.last_name + " (" + self.nickname + ")"
      if display_name.size > 27
        return display_name[0..27] + "...)"
      else
        return display_name
      end
    end
    if display_name.size > 30
      return display_name[0..30] + "..."
    else
      return display_name
    end
  end

  #----------------------------------------------------------------------------

  def full_name
    name = self.first_name
    if self.middle_name
      name = name + " " + self.middle_name
    end
    name = name + " " + self.last_name

    if !(self.nickname.nil? or self.nickname.empty?)
      name = name + " (" + self.nickname + ")"
    end
    return name
  end

  def not_visitor
    return self.role != "visitante"
  end

  def self.ordinary_users
    return User.where("role = 'morador' OR role = 'verificador' OR role = 'coordenador'")
  end

  def admin?
    self.role == "admin" or self.role == "coordenador"
  end

  def verifier?
    self.role == "admin" or self.role == "coordenador" or self.role = "verificador"
  end

  def sponsor?
    self.role == "lojista"
  end

  #----------------------------------------------------------------------------

  def carrier_requirements
    if self.carrier.downcase == "vivo"
      req = 20
    elsif self.carrier.downcase == "oi"
      req = 20
    elsif self.carrier.downcase == "claro"
      req = 17
    elsif self.carrier.downcase == "tim"
      req = 17
    elsif self.carrier.downcase == "nextel"
      req = 27
    else
      req = 20
    end
    req
  end

  #----------------------------------------------------------------------------

  def residents?
    return self.role == "morador" || self.role == "admin" || self.role == "coordenador"
  end

  #----------------------------------------------------------------------------

  def build_report_via_sms(params)
    body = params[:body].force_encoding('Windows-1252').encode('UTF-8')

    # location = Location.find_or_create_by_street_type_and_street_name_and_street_number(
    #     "Rua".downcase.titleize,
    #     "Sargento Silva Nunes".downcase.titleize,
    #     "1012".downcase.titleize
    # )
    location = Location.create
    location.update_attribute(:neighborhood_id, Neighborhood.first.id)

    report = Report.new(reporter: self, :sms => true, :status => Report::STATUS[:sms], :report => body, :neighborhood_id => self.neighborhood_id, :location => location)
    return report
  end

  #----------------------------------------------------------------------------

  def total_torpedos
    self.reports.sms.where('elimination_type IS NOT NULL')
  end

  #----------------------------------------------------------------------------

  def creditable_torpedos
    self.reports.sms.where('elimination_type IS NOT NULL').where(is_credited: nil)
  end

  #----------------------------------------------------------------------------

  def picture
    return "default_images/profile_default_image.png" if self.profile_photo_file_name.nil?
    return self.profile_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

end
