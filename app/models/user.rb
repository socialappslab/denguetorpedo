# -*- encoding : utf-8 -*-

class User < ActiveRecord::Base
  attr_accessible :locale, :neighborhood_id, :email, :username,
  :password, :password_confirmation, :auth_token, :phone_number,
  :phone_number_confirmation, :profile_photo, :is_verifier,
  :is_fully_registered, :is_health_agent, :role, :gender, :is_blocked,
  :carrier, :prepaid, :points, :total_points, :name

  #----------------------------------------------------------------------------

  ROLES = ["morador", "logista", "visitante"]
  MIN_PHONE_LENGTH = 7
  PHONE_NUMBER_PLACEHOLDER = "000000000000"

  module Types
    COORDINATOR = "coordenador"
    SPONSOR     = "lojista"
    VERIFIER    = "verificador"
    RESIDENT    = "morador"
    VISITOR     = "visitante"
  end

  # A user gets points for the following:
  # * verifying a report,
  # * submitting a report (via SMS or web),
  # * eliminating a report.
  module Points
    REPORT_VERIFIED  = 50
    REPORT_SUBMITTED = 50
    POST_CREATED     = 5
    REFERRAL         = 50

    # Points for certain badges
    WATCHER      = 50
    EXTERMINATOR = 225
    WARRIOR      = 450
    HEALTHWORKER = 675
    PROTECTOR    = 900
  end

  module Locales
    SPANISH    = "es"
    PORTUGUESE = "pt"
  end

  EMAIL_REGEX    = /[a-z0-9!$#%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!$#%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/

  has_secure_password
  has_attached_file :profile_photo, :styles => { :small => ["150x150>", :jpg], :large => ["300x300>", :jpg] }, :convert_options => { :small => "-quality 75 -strip", :large => "-quality 75 -strip" }
  validates_attachment :profile_photo, content_type: { content_type: /\Aimage\/.*\Z/ }

  #----------------------------------------------------------------------------
  # Validators
  #-----------

  validates :name,     :presence => true

  validates :username, :presence   => true
  validates :username, :uniqueness => true
  validate  :username, :has_proper_username?

  validates :password, :length => { :minimum => 4}, :if => "id.nil? || password"
  validates :neighborhood_id, :presence => true
  validates :email, :format => { :with => EMAIL_REGEX }, :allow_blank => true
  validates :points, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates :total_points, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0}

  #----------------------------------------------------------------------------
  # Filters
  #--------
  before_create { generate_token(:auth_token) }
  before_save :clean_username

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  # TODO: reports should include both eliminator_id and reporter_id.
  has_many :created_reports,    :class_name => "Report", :foreign_key => "reporter_id",   :dependent => :nullify
  has_many :eliminated_reports, :class_name => "Report", :foreign_key => "eliminator_id", :dependent => :nullify
  has_many :verified_reports,   :class_name => "Report", :foreign_key => "verifier_id",   :dependent => :nullify

  has_many :posts, :dependent => :destroy
  has_many :prize_codes, :dependent => :destroy
  has_many :badges
  has_many :prizes, :dependent => :destroy

  has_one :recruiter_relationships, :class_name => "Recruitment", :foreign_key => "recruitee_id"
  has_one :recruiter, :through => :recruiter_relationships, :source => :recruiter
  has_many :recruitee_relationships, :class_name => "Recruitment", :foreign_key => "recruiter_id"
  has_many :recruitees, :through => :recruitee_relationships, :source => :recruitee
  belongs_to :neighborhood

  has_many :likes

  scope :residents, -> { where("role = 'morador' OR role = 'coordenador'") }

  has_many :team_memberships, :dependent => :destroy
  has_many :teams, :through => :team_memberships

  has_many :notifications, :dependent => :destroy, :class_name => "UserNotification"
  has_many :csv_reports, :dependent => :destroy

  has_and_belongs_to_many :conversations

  #----------------------------------------------------------------------------

  # TODO: This is still not ideal but Rails doesn't have a clean way to load
  # an association on multiple foreign_keys. Perhaps calling created_reports
  # and eliminated_reports separately here would be faster?
  def reports
    Report.where("reporter_id = ? OR eliminator_id = ?", self.id, self.id).order("updated_at DESC")
  end

  #----------------------------------------------------------------------------

  def city
    return self.neighborhood.city
  end

  def new_notifications
    return self.notifications.where(:seen_at => nil)
  end

  #----------------------------------------------------------------------------

  def award_points_for_posting
    points = self.total_points || 0
    self.update_column(:total_points, points + Points::POST_CREATED)
    self.teams.each do |team|
      team.update_column(:points, team.points + Points::POST_CREATED)
    end
  end

  def award_points_for_submitting(report)
    points = self.total_points || 0
    self.update_column(:total_points, points + Points::REPORT_SUBMITTED)
    self.teams.each do |team|
      team.update_column(:points, team.points + Points::REPORT_SUBMITTED)
    end
  end

  def award_points_for_eliminating(report)
    points = self.total_points || 0
    self.update_column(:total_points, points + report.elimination_method.points)
    self.teams.each do |team|
      team.update_column(:points, team.points + report.elimination_method.points)
    end
  end

  #----------------------------------------------------------------------------

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

  #----------------------------------------------------------------------------

  def display_name
    return self.username
  end

  def full_name
    name = self.first_name
    if self.middle_name
      name = name + " " + self.middle_name
    end
    name = name + " " + self.last_name

    if !(self.nickname.blank?)
      name = name + " (" + self.nickname + ")"
    end
    return name
  end

  #----------------------------------------------------------------------------
  # User roles

  def coordinator?
    return self.role == User::Types::COORDINATOR
  end

  def verifier?
    return (self.role ==  User::Types::COORDINATOR || self.role == User::Types::VERIFIER)
  end

  def sponsor?
    self.role == User::Types::SPONSOR
  end

  def residents?
    return [User::Types::RESIDENT, User::Types::COORDINATOR].include?(self.role)
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

  def picture
    if self.profile_photo_file_name.nil?
      return "default_images/default_sponsor_image.jpg" if self.role == User::Types::SPONSOR
      return "default_images/profile_default_image.png"
    end

    return self.profile_photo.url(:large)
  end

  #----------------------------------------------------------------------------

  # A user is associated with a location if
  # a) They created a report for that location, and/or
  # b) They eliminated a report for that location,
  # c) They uploaded a CSV for that location.
  def locations
    report_loc_ids     = self.reports.pluck(:location_id)
    csv_report_loc_ids = self.csv_reports.pluck(:location_id)
    loc_ids = (report_loc_ids + csv_report_loc_ids).uniq
    return Location.where(:id => loc_ids)
  end

  def green_locations
    self.locations.find_all {|l| l.green?}
  end

  #----------------------------------------------------------------------------

  private

  def clean_username
    self.username = self.username.strip.downcase if self.username.present?
  end

  def has_proper_username?
    return true if self.username.blank?

    if (self.username =~ /^(\w)+$/).nil?
      self.errors.add(:username, I18n.t("activerecord.errors.users.invalid_username"))
      return false
    end

    return true
  end

  #----------------------------------------------------------------------------

end
