# -*- encoding : utf-8 -*-

class Report < ActiveRecord::Base
  attr_accessible :report, :pupae, :created_at, :neighborhood_id, :breeding_site_id,
  :elimination_method_id, :before_photo, :after_photo, :status, :reporter_id,
  :location, :location_attributes, :breeding_site, :eliminator_id, :verifier_id,
  :location_id, :reporter, :sms, :is_credited, :credited_at, :completed_at,
  :verifier, :resolved_verifier, :eliminator, :eliminated_at, :csv_report_id,
  :protected, :chemically_treated, :larvae, :field_identifier
  # attr_readonly :likes_count

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

  # This is the minimum time threshold that we allow between created_at and
  # eliminated_at.
  ELIMINATION_THRESHOLD = 1.minute

  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo,
  :default_url => 'default_images/report_before_photo.png', :styles => {
    :large => ["450x450>", :jpg],
    :medium => "300x300>"
  }, :convert_options => { :medium => "-quality 75 -strip", :large => "-quality 75 -strip" }

  has_attached_file :after_photo,
  :default_url => 'default_images/report_after_photo.png', :styles => {
    :large => ["450x450>", :jpg],
    :medium => "300x300>"
  }, :convert_options => { :medium => "-quality 75 -strip", :large => "-quality 75 -strip" }

  attr_accessor :save_without_before_photo
  attr_accessor :save_without_after_photo

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  belongs_to :location
  belongs_to :neighborhood
  belongs_to :breeding_site
  belongs_to :elimination_method

  has_many :likes,    :as => :likeable,    :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :inspections, :dependent => :destroy
  has_many :visits,      :through => :inspections

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

  validates :neighborhood_id,  :presence => true
  validates :report,           :presence => true
  validates :reporter_id,      :presence => true
  validates :breeding_site_id, :presence => true
  validates :before_photo,     :presence => {:on => :create}, :unless => Proc.new {|file| self.save_without_before_photo == true}

  validates :after_photo,           :presence => {:on => :update, :if => :verified?}, :unless => Proc.new {|file| self.save_without_after_photo == true}
  validates :elimination_method_id, :presence => {:on => :update, :if => :verified?}

  validates_attachment :before_photo, content_type: { content_type: /\Aimage\/.*\Z/ }, :unless => Proc.new {|file| self.save_without_before_photo == true}
  validates_attachment :after_photo,  content_type: { content_type: /\Aimage\/.*\Z/ }, :unless => Proc.new {|file| self.save_without_after_photo == true}

  validate :created_at,    :inspected_in_the_past?
  validate :created_at,    :inspected_after_two_thousand_fourteen?
  validate :eliminated_at, :eliminated_after_creation?
  validate :eliminated_at, :eliminated_in_the_past?

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :location

  scope :sms,         -> { where(sms: true).order(:created_at) }
  scope :displayable, -> { where("larvae = ? OR pupae = ? OR protected = ? OR protected IS NULL", true, true, false) }
  scope :completed,   -> { where("verified_at IS NOT NULL") }
  scope :incomplete,  -> { where("verified_at IS NULL") }
  scope :eliminated,  -> { where("eliminated_at IS NOT NULL AND elimination_method_id IS NOT NULL") }

  # NOTE: This scope is awkwardly named because we get the following warning:
  # Creating scope :open. Overwriting existing method Report.open.
  scope :is_open,        -> { where("eliminated_at IS NULL OR elimination_method_id IS NULL") }

  #----------------------------------------------------------------------------
  # Callbacks
  #----------

  # This callback will change the minimum difference between created_at and
  # eliminated_at to be 1 second, if they equal.
  before_save :set_elimination_threshold

  #----------------------------------------------------------------------------
  # These methods are the authoritative way of determining if a report
  # is eliminated, open, expired or SMS.

  def initial_visit
    return self.visits.where(:parent_visit_id => nil).first
  end

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

  # We define an incomplete report to be a report that was created from
  # an SMS OR a CSV report.
  def incomplete?
    if self.prepared_at == nil
      return true if self.csv_report_id.present?
      return true if self.sms.present?
    end

    return false
  end

  def verified?
    return self.verified_at.present?
  end

  # TODO: Deprecate this as we don't have prizes anymore.
  def expired?
    return false if self.eliminated?
    return Time.zone.now > self.expire_date
  end

  #----------------------------------------------------------------------------

  def formatted_created_at
    return "" if self.created_at.blank?
    return self.created_at.strftime("%Y-%m-%d %H:%M")
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
    update_attributes(is_credited: true, credited_at: Time.zone.now)
  end

  #----------------------------------------------------------------------------

  def discredit
    update_attributes(is_credited: false, credited_at: Time.zone.now)
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

  def self.statuses_as_symbols
    return {
      Status::POSITIVE  => :positive,
      Status::POTENTIAL => :potential,
      Status::NEGATIVE  => :negative
    }
  end

  #----------------------------------------------------------------------------

  def elimination_method_picture
    if self.after_photo_file_name.nil?
      return nil
    end

    return self.after_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

  # A new report offers conceptually implies a visit to some location.
  # Specifically, the report tells us *what* was identified at the location,
  # and *when* it was identified. The *what* depends on what other reports
  # correspond to that location, so it will be calculated appropriately.
  # Specifically, to update or set the identification_type based on the following information:
  # * If report is status = POSITIVE, then the identification_type is POSITIVE
  # * If report is status = POTENTIAL, then set to POTENTIAL only if identification_type
  #   of existing Visit does not equal POSITIVE.
  # This method should be used when we first create a new report.
  def find_or_create_first_visit
    return nil if self.location_id.blank?

    v = Visit.where(:location_id => self.location_id)
    v = v.where(:parent_visit_id => nil)
    v = v.where(:visited_at => (self.created_at.beginning_of_day..self.created_at.end_of_day))
    v = v.order("visited_at DESC").first
    if v.blank?
      v             = Visit.new
      v.location_id = self.location_id
      v.visited_at  = self.created_at
      v.save
    end

    return v
  end

  def find_or_create_followup_visit(visited_at)
    return nil if self.location_id.blank?

    v = Visit.where(:location_id => self.location_id)
    v = v.where("parent_visit_id IS NOT NULL")
    v = v.where(:visited_at => (visited_at.beginning_of_day..visited_at.end_of_day))
    v = v.order("visited_at DESC").first
    if v.blank?
      v             = Visit.new
      v.location_id = self.location_id
      v.parent_visit_id = self.initial_visit.id if self.initial_visit.present?
      v.visited_at  = visited_at
      v.save
    end

    return v
  end

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
  def find_or_create_elimination_visit
    return if self.location_id.blank?
    # return if self.completed_at.blank?
    return if self.eliminated_at.blank?

    v = Visit.where(:location_id => self.location_id)
    v = v.where("parent_visit_id IS NOT NULL")
    v = v.where(:visited_at => (self.eliminated_at.beginning_of_day..self.eliminated_at.end_of_day))
    v = v.order("visited_at DESC").limit(1)
    if v.blank?
      v                 = Visit.new
      v.location_id     = self.location_id
      v.parent_visit_id = self.initial_visit.id if self.initial_visit.present?
      v.visited_at      = self.eliminated_at
      v.save
    else
      v = v.first
    end

    return v
  end

  def update_inspection_for_visit(v)
    return if v.blank?

    # At this point, we've identified a visit. Let's save it and create an
    # inspection for the report.
    ins = self.inspections.where(:visit_id => v.id).first
    ins = Inspection.new(:visit_id => v.id, :report_id => self.id) if ins.blank?
    ins.identification_type = self.status
    ins.save
  end

  #----------------------------------------------------------------------------



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

  # Since the CSV report doesn't encode the *time of day*, we
  # end up with a situation where an initial report and an elimination report
  # will have the same 'created_at/eliminated_at' timestamp. To remedy this, we will
  # check to see if the 2 columns match. If they do, then we will
  # set the difference to be the threshold.
  def set_elimination_threshold
    return true if self.created_at.blank?
    return true if self.eliminated_at.blank?

    self.eliminated_at += ELIMINATION_THRESHOLD if (self.created_at - self.eliminated_at).abs < ELIMINATION_THRESHOLD
  end

  #------------------
  # Validator helpers
  #------------------

  def eliminated_after_creation?
    return true if self.eliminated_at.blank?

    # If the report hasn't been created yet, then let's compare elimination time
    # to the current time. Otherwise, let's compare to the time of creation.
    if self.created_at.blank?
      return true if self.eliminated_at >= Time.zone.now
    else
      # NOTE: We need to check for equality in case some records had their dates
      # set to beginning of day (before we were handling time of day).
      return true if self.eliminated_at >= self.created_at
    end

    created_at = I18n.t("activerecord.attributes.report.created_at") || "inspection date"
    self.errors[:eliminated_at] << "can't be before " + created_at.downcase
    return false
  end

  def inspected_in_the_past?
    return true if self.created_at.blank?
    return true if self.created_at.past?

    self.errors[:created_at] << "can't be in the future"
    return false
  end

  def inspected_after_two_thousand_fourteen?
    return true if self.created_at.blank?
    return true if self.created_at.year >= 2014

    self.errors[:created_at] << "can't be before 2014"
    return false
  end

  def eliminated_in_the_past?
    return true if self.eliminated_at.blank?
    return true if self.eliminated_at.past?

    self.errors[:eliminated_at] << "can't be in the future"
    return false
  end

  #----------------------------------------------------------------------------

end
