# encoding: utf-8

class Report < ActiveRecord::Base
  attr_accessible :report, :neighborhood_id, :before_photo, :after_photo, :status, :reporter_id, :location, :location_attributes,
    :elimination_type, :elimination_method, :verifier_id, :reporter_name,
    :eliminator_name, :location_id, :reporter, :sms, :is_credited, :credited_at,
    :completed_at, :verifier, :resolved_verifier, :eliminator

  #----------------------------------------------------------------------------

  # callback to create the feeds
  after_save do |report|
    Feed.create_from_object(report, report.reporter_id, STATUS[:reported]) if report.reporter_id_changed?
    Feed.create_from_object(report, report.eliminator_id, STATUS[:eliminated]) if report.eliminator_id_changed?
  end

  #----------------------------------------------------------------------------

  STATUS = {:eliminated => 'eliminated', :reported => 'reported', :sms => 'sms'}

  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo, :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_before_photo.png'
  has_attached_file :after_photo,  :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_after_photo.png'


  #----------------------------------------------------------------------------
  # Associations
  #-------------

  has_many :feeds, :as => :target
  belongs_to :location
  belongs_to :neighborhood

  # The following belongs_to define all the types of users that a report
  # can have.
  belongs_to :reporter, :class_name => "User"
  belongs_to :eliminator, :class_name => "User"
  belongs_to :verifier, :class_name => "User"
  belongs_to :resolved_verifier, :class_name => "User"

  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable

  #----------------------------------------------------------------------------
  # Validations
  #-------------
  # TODO :report validation fails unexpectedly
  # When creating a new report and a user doesn't submit a picture, he'll get an error to add a picture
  # After adding a picture if the user tries to submit again they'll get an error about having to provide
  #  a description. Despite the fact that the description field in filled AND the model object shows it as not being blank


  # TODO refactor this code to be cleaner and find a better solution for all the scenarios
  validates :neighborhood_id, :report, :reporter_id, :status, :presence => true


  # SMS creation
  validates :sms, :presence => true, :if => :sms?

  # Web report creation
  validates :before_photo, :elimination_type, :presence => true, :unless => :sms?

  # Updating a SMS
  validates :before_photo, :elimination_type, :presence => {:on => :update, :if => :sms_incomplete? }

  # Eliminating a report
  validates :after_photo, :elimination_method, :presence => {:on => :update, :unless => :sms_incomplete?}

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :location

  scope :sms, where(sms: true).order(:created_at)
  scope :type_selected, where("elimination_type IS NOT NULL")

  before_save :set_names

  #----------------------------------------------------------------------------
  # These methods are the authoritative way of determining if a report
  # is eliminated, open, expired or SMS.

  def is_eliminated?
    return self.status == Report::STATUS[:eliminated]
  end

  def eliminated?
    return self.is_eliminated?
  end

  # NOTE: Open does not mean active. An open report can be expired.
  def is_open?
    return self.status == Report::STATUS[:reported]
  end

  def open?
    return self.is_open?
  end

  def sms_incomplete?
    return (self.sms && self.completed_at == nil)
  end

  # We define a report to be public if it's not SMS.
  # TODO: This is obviously not a future proof solution, so come back to this
  # when you're ready.
  def is_public?
    return !self.sms
  end

  def public?
    return self.is_public?
  end

  def expired?
    self.completed_at and self.completed_at + 3600 * 24 * 2 < Time.new
  end

  # A valid report is a report that is
  # a) open, and verified to be valid by a 3rd party, OR
  # b) eliminated, and verified to be valid by a 3rd party.
  def is_valid?
    if self.is_open?
      return (self.isVerified == "t")
    elsif self.is_eliminated?
      return (self.is_resolved_verified == "t")
    end
  end

  # A valid report is a report that is
  # a) open, and verified to be problematic by a 3rd party, OR
  # b) eliminated, and verified to be problematic by a 3rd party.
  def is_invalid?
    if self.is_open?
      return (self.isVerified == "f")
    elsif self.is_eliminated?
      return (self.is_resolved_verified == "f")
    end
  end

  def invalid?
    return self.is_invalid?
  end

  #----------------------------------------------------------------------------

  def self.create_from_user(report_content, params)
    create(:report => report_content) do |r|
      r.reporter_id = params[:reporter] && params[:reporter].id
      r.location_id = params[:location] && params[:location].id
      r.status = params[:status]

      # optional parameters
      r.eliminator_id = params[:eliminator] && params[:eliminator].id

      if params[:before_photo]
        r.before_photo = params[:before_photo]
      end

      if params[:after_photo]
        r.after_photo = params[:after_photo]
      end
    end
  end

  #----------------------------------------------------------------------------

  def creditar
    update_attributes(is_credited: nil, credited_at: nil)
  end

  #----------------------------------------------------------------------------

  def credit
    update_attributes(is_credited: true, credited_at: Time.now)
  end

  #----------------------------------------------------------------------------

  def discredit
    update_attributes(is_credited: false, credited_at: Time.now)
  end


  #----------------------------------------------------------------------------

  def strftime_with(type)
    if type == :created_at
      self.created_at.strftime("%d/%m/%Y")
    elsif type == :updated_at
      self.updated_at.strftime("%d/%m/%Y")
    elsif type == :eliminated_at
      self.eliminated_at != nil ? self.eliminated_at.strftime("%d/%m/%Y") : ""
    else
      ""
    end
  end

  def self.identified_reports
    where(:status => STATUS[:reported])
  end

  def self.eliminated_reports
    where(:status => STATUS[:eliminated])
  end

  #----------------------------------------------------------------------------

  def complete_address
    return self.location.complete_address if self.location.present?
  end

  #----------------------------------------------------------------------------

  def expire_date
    self.completed_at + 3600 * 50
  end

  def set_names
    if self.reporter
      self.reporter_name = self.reporter.display_name
    end

    if self.eliminator
      self.eliminator_name = self.eliminator.display_name
    end

    if self.verifier
      self.verifier_name = self.verifier.display_name
    end

    if self.resolved_verifier
      self.verifier_name = self.resolved_verifier.display_name
    end
  end

  def deduct_points
    if self.eliminator
      if self.is_resolved_verified == false
        self.eliminator.update_attributes(points: self.eliminator.points - 400)
      end
    else
      self.reporter.update_attributes(points: self.reporter.points - 100)
    end
  end

  #----------------------------------------------------------------------------

end
