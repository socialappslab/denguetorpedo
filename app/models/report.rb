# encoding: utf-8

class Report < ActiveRecord::Base
  attr_accessible :report, :neighborhood_id, :breeding_site_id,
  :elimination_method_id, :before_photo, :after_photo, :status, :reporter_id,
  :location, :location_attributes, :breeding_site, :eliminator_id, :verifier_id,
  :location_id, :reporter, :sms, :is_credited, :credited_at, :completed_at,
  :verifier, :resolved_verifier, :eliminator

  #----------------------------------------------------------------------------
  # Constants

  EXPIRATION_WINDOW = 48 * 3600 # in seconds

  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo, :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_before_photo.png'
  has_attached_file :after_photo,  :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_after_photo.png'

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  belongs_to :location
  belongs_to :neighborhood
  belongs_to :breeding_site
  belongs_to :elimination_method
  has_many :likes,    :as => :likeable
  has_many :comments, :as => :commentable

  # The following associations define all stakeholders in the reporting
  # process.
  belongs_to :reporter,          :class_name => "User"
  belongs_to :eliminator,        :class_name => "User"
  belongs_to :verifier,          :class_name => "User"
  belongs_to :resolved_verifier, :class_name => "User"


  #----------------------------------------------------------------------------
  # Validations
  #-------------
  # TODO :report validation fails unexpectedly:
  # * When creating a new report and a user doesn't submit a picture, he'll get an error to add a picture
  # * After adding a picture if the user tries to submit again they'll get an error about having to provide
  #  a description. Despite the fact that the description field in filled AND the model object shows it as not being blank

  # TODO refactor this code to be cleaner and find a better solution for all the scenarios
  validates :neighborhood_id, :presence => true
  validates :report,          :presence => true
  validates :reporter_id,     :presence => true

  # SMS creation
  validates :sms, :presence => true, :if => :sms?

  # Validation on photos
  validates :before_photo, :presence => true, :unless => :sms?
  validates :before_photo, :presence => {:on => :update, :if => :sms_incomplete? }
  validates :after_photo, :presence => {:on => :update, :unless => :sms_incomplete?}

  # Validation on breeding sites, and elimination types.
  validates :breeding_site_id, :presence => true, :unless => :sms?
  validates :breeding_site_id, :presence => {:on => :update, :if => :sms_incomplete? }
  validates :elimination_method_id, :presence => {:on => :update, :unless => :sms_incomplete?}

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :location

  scope :sms, where(sms: true).order(:created_at)

  #----------------------------------------------------------------------------
  # These methods are the authoritative way of determining if a report
  # is eliminated, open, expired or SMS.

  def eliminated?
    return self.elimination_method_id.present?
  end

  # NOTE: Open does not mean active. An open report can be expired.
  def open?
    return self.elimination_method_id.blank?
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
    return false if self.eliminated?
    return Time.now > self.created_at + EXPIRATION_WINDOW
  end

  # A valid report is a report that is
  # a) open, and verified to be valid by a 3rd party, OR
  # b) eliminated, and verified to be valid by a 3rd party.
  def is_valid?
    if self.open?
      return (self.isVerified == "t")
    elsif self.eliminated?
      return (self.is_resolved_verified == "t")
    end
  end

  # A valid report is a report that is
  # a) open, and verified to be problematic by a 3rd party, OR
  # b) eliminated, and verified to be problematic by a 3rd party.
  def is_invalid?
    if self.open?
      return (self.isVerified == "f")
    elsif self.eliminated?
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

  # TODO: Deprecate this
  def self.eliminated_reports
    return Report.all.find_all { |r| r.eliminated? }
  end

  #----------------------------------------------------------------------------

  def complete_address
    return self.location.complete_address if self.location.present?
  end

  #----------------------------------------------------------------------------

  def expire_date
    self.created_at + EXPIRATION_WINDOW
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

  def breeding_site_picture
    if self.before_photo_file_name.nil?
      return nil
    end

    return self.before_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

  def elimination_method_picture
    if self.after_photo_file_name.nil?
      return nil
    end

    return self.after_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

end
