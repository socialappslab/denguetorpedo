# -*- encoding : utf-8 -*-

class User < ActiveRecord::Base
  attr_accessible :locale, :neighborhood_id, :email, :username,
  :password, :password_confirmation, :auth_token, :phone_number,
  :phone_number_confirmation, :profile_photo, :is_verifier,
  :is_fully_registered, :is_health_agent, :role, :gender, :is_blocked,
  :carrier, :prepaid, :points, :total_points, :name

  has_many :user_locations
  has_many :locations, :through => :user_locations
  has_many :memberships
  has_many :organizations, :through => :memberships
  has_and_belongs_to_many :assignments

  #----------------------------------------------------------------------------

  def selected_membership
    active_m = self.memberships.find_by(:active => true)
    if active_m.blank?
      active_m = self.memberships.first
      active_m.update_column(:active, true)
    end

    return active_m
  end

  #----------------------------------------------------------------------------

  def jwt_token
    return JWT.encode(self.payload, ENV['JWT_SECRET'], 'HS256')
  end

  def payload
    if self.role == Types::COORDINATOR
      scopes = ['add_visits', 'change_visits', 'remove_visits', 'add_houses', 'change_houses', 'remove_houses', 'add_inspections', 'change_inspections', 'remove_inspections', 'add_breeding_sites', 'change_breeding_sites', 'remove_breeding_sites']
    else
      scopes = ['add_visits', 'change_visits', 'add_houses', 'change_houses', 'add_inspections', 'change_inspections', 'add_breeding_sites', 'change_breeding_sites']
    end

    {
      exp: Time.now.to_i + 24 * 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: scopes,
      user: {
        id:       self.id,
        username: self.username,
        email:    self.email
      }
    }
  end

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
    DELEGATE    = "delegado"
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
    GREEN_HOUSE      = 200

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
  validates :points, :numericality => { :only_integer => true }
  validates :total_points, :numericality => { :only_integer => true}

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
  
  has_many :created_inspections,    :class_name => "Inspection", :foreign_key => "reporter_id",   :dependent => :nullify
  has_many :eliminated_inspections, :class_name => "Inspection", :foreign_key => "eliminator_id", :dependent => :nullify
  has_many :verified_inspections,   :class_name => "Inspection", :foreign_key => "verifier_id",   :dependent => :nullify

  has_many :posts, :dependent => :destroy
  has_many :comments, :through => :posts
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
  has_many :csv_reports, :dependent => :destroy # TODO: I think we should deprecate it at some point.
  has_many :csvs, :dependent => :destroy, :class_name => "Spreadsheet"

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

  def total_points
    [self.attributes["total_points"] || 0, 0].max
  end

  # A user's points consist of two things:
  # 1. The total_points column, and
  # 2. The 250*N calculation, where N is the number of green houses.
  def total_total_points
    num_greens = GreenLocationRankings.score_for_user(self) || 0
    return (num_greens * Points::GREEN_HOUSE + self.total_points).to_i
  end

  #----------------------------------------------------------------------------

  def award_points_for_posting
    points = self.total_points || 0
    self.update_column(:total_points, points + Points::POST_CREATED)
    self.teams.each do |team|
      team.update_column(:points, team.points + Points::POST_CREATED)
    end
  end

  def award_points_for_submitting(report=nil)
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

  def delegator?
    self.role == User::Types::DELEGATE
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
      email = self.email || (self.username + "@mailinator.com")
      gravatar_id = Digest::MD5.hexdigest(email)
      return "https://gravatar.com/avatar/#{gravatar_id}.png?r=pg&s=80&d=retro"
    end

    return self.profile_photo.url(:large)
  end

  #----------------------------------------------------------------------------

  # A user is associated with a location if
  # a) They created a report for that location, and/or
  # b) They eliminated a report for that location,
  # NOTE: We do not count CSV uploaded locations as proper locations
  # because that might force the wrong incentives (e.g. upload many CSV reports
  # and reap rewards for other people's work).
  # def locations
  #   loc_ids     = self.reports.pluck(:location_id)
  #   return Location.where(:id => loc_ids)
  # end

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
