# encoding: utf-8

class Report < ActiveRecord::Base
  attr_accessible :report, :created_at, :neighborhood_id, :breeding_site_id,
  :elimination_method_id, :before_photo, :after_photo, :status, :reporter_id,
  :location, :location_attributes, :breeding_site, :eliminator_id, :verifier_id,
  :location_id, :reporter, :sms, :is_credited, :credited_at, :completed_at,
  :verifier, :resolved_verifier, :eliminator, :eliminated_at, :csv_report_id,
  :protected, :chemically_treated, :larvae

  #----------------------------------------------------------------------------
  # Constants

  EXPIRATION_WINDOW = 48 * 3600 # in seconds

  # The status of a report defines whether it's positive (has larvae or pupae),
  # potential (no larvae, pupae) or negative (protected, or eliminated)
  module Status
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
  end

  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo,
  :default_url => 'default_images/report_before_photo.png', :styles => {
    :large => ["300x300>", :jpg],
    :medium => "150x150>",
    :thumb => "100x100>"
  }
  has_attached_file :after_photo,
  :default_url => 'default_images/report_after_photo.png', :styles => {
    :large => ["300x300>", :jpg],
    :medium => "150x150>",
    :thumb => "100x100>"
  }
  validates_attachment :before_photo, content_type: { content_type: /\Aimage\/.*\Z/ }
  validates_attachment :after_photo, content_type:  { content_type: /\Aimage\/.*\Z/ }

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
  belongs_to :csv_report

  # We're going to use prepared_at until we can deprecate completed_at
  alias_attribute :prepared_at, :completed_at


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
  validates :before_photo, :presence => {:on => :update, :if => :incomplete? }
  validates :after_photo, :presence => {:on => :update, :unless => :incomplete?}

  # Validation on breeding sites, and elimination types.
  validates :breeding_site_id, :presence => true, :unless => :sms?
  validates :breeding_site_id, :presence => {:on => :update, :if => :incomplete? }
  validates :elimination_method_id, :presence => {:on => :update, :unless => :incomplete?}

  validate :eliminated_at, :eliminated_after_creation?

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :location

  scope :sms, where(sms: true).order(:created_at)

  #----------------------------------------------------------------------------
  # Callbacks
  #----------

  # Every time a report gets created/updated, conceptually a visit must take place
  # at some location. Whether it's an identification or followup visit depends
  # on how the report is created/updated and with what attributes.
  after_commit :create_identification_visit, :on => :create
  after_commit :create_followup_visit,       :on => :update
  # after_commit :destroy_visit,               :on => :destroy

  #----------------------------------------------------------------------------
  # These methods are the authoritative way of determining if a report
  # is eliminated, open, expired or SMS.

  # This method returns the report's original status, which is the status
  # that the report had when it was first created.
  def original_status
    return Report::Status::POSITIVE if (self.larvae || self.pupae)
    return Report::Status::NEGATIVE if (self.protected)
    return Report::Status::POTENTIAL
  end

  # This is the authoritative method for the report's status since it also
  # considers the report's elimination state.
  def status
    return Status::NEGATIVE if self.eliminated?
    return self.original_status
  end

  def eliminated?
    return (self.eliminated_at.present? && self.elimination_method_id.present?)
  end

  # NOTE: Open does not mean active. An open report can be expired.
  def open?
    return (self.eliminated_at.blank? || self.elimination_method_id.blank?)
  end

  # TODO: Deprecate this in favor for incomplete?
  def sms_incomplete?
    return (self.sms && self.prepared_at == nil)
  end

  # We define an incomplete report to be a report that was created from
  # an SMS OR a CSV report.
  def incomplete?
    if self.prepared_at == nil
      return true if self.csv_report_id.present?
      return true if self.sms.present?
    end

    return false
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
    return Time.now > self.expire_date
  end

  # A valid report is a report that is
  # a) open, and verified to be valid by a 3rd party, OR
  # b) eliminated, and verified to be valid by a 3rd party.
  # TODO: For now, we define a valid report to be a report
  # that was verified (no matter what state)
  def is_valid?
    # if self.open?
    #   return (self.isVerified == "t")
    # elsif self.eliminated?
    #   return (self.is_resolved_verified == "t")
    # end

    return nil if self.verifier_id.blank?
    return self.isVerified == "t"
  end

  # A valid report is a report that is
  # a) open, and verified to be problematic by a 3rd party, OR
  # b) eliminated, and verified to be problematic by a 3rd party.
  # TODO: For now, we define a valid report to be a report
  # that was verified (no matter what state)
  def is_invalid?
    # if self.open?
    #   return (self.isVerified == "f")
    # elsif self.eliminated?
    #   return (self.is_resolved_verified == "f")
    # end

    return nil if self.verifier_id.blank?
    return self.isVerified == "f"
  end

  def invalid?
    return self.is_invalid?
  end

  #----------------------------------------------------------------------------

  def formatted_created_at
    return self.created_at.strftime("%k:%M %Y-%m-%d")
  end

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

  # TODO: Deprecate this.
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

  def descriptive_address
    return "" if self.location.nil?
    return self.location.descriptive_address
  end

  #----------------------------------------------------------------------------

  def expire_date
    self.completed_at + EXPIRATION_WINDOW
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

  # This method is run when the report is created. Each report essentially
  # represents the identification type of a location.
  #


  # A new report offers conceptually implies a visit to some location.
  # Specifically, the report tells us *what* was identified at the location,
  # and *when* it was identified. The *what* depends on what other reports
  # correspond to that location, so it will be calculated appropriately.
  # Specifically, to update or set the identification_type based on the following information:
  # * If report is status = POSITIVE, then the identification_type is POSITIVE
  # * If report is status = POTENTIAL, then set to POTENTIAL only if identification_type
  #   of existing Visit does not equal POSITIVE.
  def create_identification_visit
    return if self.location_id.blank?

    ls = Visit.where(:location_id => self.location_id)
    ls = ls.where(:visit_type => Visit::Types::INSPECTION)
    ls = ls.where(:visited_at => (self.created_at.beginning_of_day..self.created_at.end_of_day))
    ls = ls.order("visited_at DESC").limit(1)
    if ls.blank?
      ls             = Visit.new
      ls.visit_type  = Visit::Types::INSPECTION
      ls.location_id = self.location_id
      ls.visited_at  = self.created_at
    else
      ls = ls.first
    end

    ls.identification_type = ls.calculate_identification_type_for_report(self)
    ls.save

    # Finally, associate the report with a particular visit.
    # self.update_column(:visit_id, ls.id)
  end

  #----------------------------------------------------------------------------

  # This method is run when the report is *eliminated*. Again, the eliminated
  # report gleams some insight into the state of the location. Whether the location
  # is actually cleaned or not depends on all other reports, however. Therefore,
  # we update cleaned_at ONLY IF all reports have been eliminated. We set cleaned_at
  # to be the time of the incoming report's eliminated_at time.
  #
  # What Visit are we updating? The one whose identified_at corresponds
  # to the report's created_at date. This ensures consistency between the
  # create_visit method, and this method so we're working on the same
  # Visit.
  def create_followup_visit
    return if self.location_id.blank?
    return if self.eliminated_at.blank?

    ls = Visit.where(:location_id => self.location_id)
    ls = ls.where(:visit_type => Visit::Types::FOLLOWUP)
    ls = ls.where(:visited_at => (self.eliminated_at.beginning_of_day..self.eliminated_at.end_of_day))
    ls = ls.order("visited_at DESC").limit(1)
    if ls.blank?
      ls             = Visit.new
      ls.location_id = self.location_id
      ls.visit_type  = Visit::Types::FOLLOWUP
      ls.visited_at  = self.eliminated_at
    else
      ls = ls.first
    end

    # Now, let's update cleaned_at column only if there are no more positive/potential
    # reports.
    ls.identification_type = ls.calculate_identification_type_for_report(self)
    ls.save

    # Finally, associate the report with a particular visit if it's not associated yet.
    # self.update_column(:visit_id, ls.id) if self.visit_id.blank?
  end

  #----------------------------------------------------------------------------

  # This method is run when the report is *destroyed*. We want to make sure that
  # if this is the last report associated with the Visit, then make sure to
  # destroy that visit.
  # def destroy_visit
  #   return if self.visit_id.blank?
  #
  #   remaining_reports_count = Report.where(:visit_id => self.visit_id).count
  #   Visit.find(self.visit_id).destroy if remaining_reports_count == 0
  # end

  #----------------------------------------------------------------------------


  # NOTE: We have to use this hack (even though Paperclip handles base64 images)
  # because we want to explicitly specify the content type and filename. Some
  # of this is taken from
  # https://github.com/thoughtbot/paperclip/blob/master/lib/paperclip/io_adapters/data_uri_adapter.rb
  # and
  # https://gist.github.com/WizardOfOgz/1012107
  def self.base64_image_to_paperclip(base64_image, filename = nil)
    regexp = /\Adata:([-\w]+\/[-\w\+\.]+)?;base64,(.*)/m
    data_uri_parts = base64_image.match(regexp) || []
    data = StringIO.new(Base64.decode64(data_uri_parts[2] || ''))
    data.class_eval do
      attr_accessor :content_type, :original_filename
    end
    data.content_type = "image/jpeg"
    data.original_filename = filename || SecureRandom.base64 + ".jpg"

    return data
  end

  #----------------------------------------------------------------------------

  private

  # Validator that ensures that eliminated_at is after created_at.
  def eliminated_after_creation?
    return true if self.eliminated_at.blank?

    # If the report hasn't been created yet, then let's compare elimination time
    # to the current time. Otherwise, let's compare to the time of creation.
    if self.created_at.blank?
      return true if self.eliminated_at > Time.now
    else
      return true if self.eliminated_at > self.created_at
    end

    created_at = I18n.t("activerecord.attributes.report.created_at") || "inspection date"
    self.errors[:eliminated_at] << "can't be before " + created_at.downcase
    return false
  end

end
