# encoding: utf-8
# == Schema Information
#
# Table name: reports
#
#  id                        :integer          not null, primary key
#  report                    :text
#  reporter_id               :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  status_cd                 :integer
#  eliminator_id             :integer
#  location_id               :integer
#  before_photo_file_name    :string(255)
#  before_photo_content_type :string(255)
#  before_photo_file_size    :integer
#  before_photo_updated_at   :datetime
#  after_photo_file_name     :string(255)
#  after_photo_content_type  :string(255)
#  after_photo_file_size     :integer
#  after_photo_updated_at    :datetime
#  eliminated_at             :datetime
#  elimination_type          :string(255)
#  elimination_method        :string(255)
#  isVerified                :string(255)
#  verifier_id               :integer
#  verified_at               :datetime
#  resolved_verifier_id      :integer
#  resolved_verified_at      :datetime
#  is_resolved_verified      :string(255)
#  sms                       :boolean          default(FALSE)
#  reporter_name             :string(255)      default("")
#  eliminator_name           :string(255)      default("")
#  verifier_name             :string(255)      default("")
#  completed_at              :datetime
#  credited_at               :datetime
#  is_credited               :boolean
#


class Report < ActiveRecord::Base
  attr_accessible :report, :before_photo, :after_photo, :status, :reporter_id, :location, :location_attributes,
    :elimination_type, :elimination_method, :verifier_id, :reporter_name,
    :eliminator_name, :location_id, :reporter, :sms, :is_credited, :credited_at,
    :completed_at, :verifier, :resolved_verifier, :eliminator

  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo, :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_before_photo.png'
  has_attached_file :after_photo,  :styles => {:medium => "150x150>", :thumb => "100x100>"}, :default_url => 'default_images/report_after_photo.png'

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  has_many :feeds, :as => :target
  belongs_to :reporter, :class_name => "User"
  belongs_to :eliminator, :class_name => "User"
  belongs_to :location
  belongs_to :verifier, :class_name => "User"
  belongs_to :resolved_verifier, :class_name => "User"
  validates :reporter_id, :presence => true
  validates :location_id, :presence => { on: :update }
  validates :status, :presence => true, unless: :sms?

  #----------------------------------------------------------------------------

  accepts_nested_attributes_for :location

  as_enum :status, [:reported, :eliminated, :sms_reported]

  scope :sms, where(sms: true).order(:created_at)
  scope :type_selected, where("elimination_type IS NOT NULL")

  before_save :set_names

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

  # callback to create the feeds
  after_save do |report|
    Feed.create_from_object(report, report.reporter_id, :reported) if report.reporter_id_changed?
    Feed.create_from_object(report, report.eliminator_id, :eliminated) if report.eliminator_id_changed?
  end

  #----------------------------------------------------------------------------

  def neighborhood
    location.neighborhood
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
    where(:status_cd => Report.reported)
  end

  def self.eliminated_reports
    where(:status_cd => Report.eliminated)
  end

  #----------------------------------------------------------------------------

  def complete_address
    return self.location.complete_address if self.location.present?
  end

  #----------------------------------------------------------------------------

  def self.within_bounds(bounds)
    reports_in_bounds = []
    for report in Report.all(:order => "created_at desc")
      if self.inBounds(report.location, bounds)
        reports_in_bounds.append(report)
        puts report.inspect + ' added'
      end
    end
    return reports_in_bounds
  end

  def self.inBounds(location, bounds)
    swlng = bounds[1]
    swlat = bounds[0]
    nelng = bounds[3]
    nelat = bounds[2]
    sw = Geokit::LatLng.new(swlat, swlng)
    ne = Geokit::LatLng.new(nelat, nelng)
    calculated_bounds = Geokit::Bounds.new(sw,ne)
    point = Geokit::LatLng.new(location.latitude, location.longitude)
    return calculated_bounds.contains?(point)
  end

  def expired?
    self.completed_at and self.completed_at + 3600 * 24 * 2 < Time.new
  end

  def expire_date
    self.completed_at + 3600 * 50
  end

  def not_sms?
    not sms
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

  def method_prompt
    if self.elimination_type
      "Selecione o método de eliminação"
    else
      "Método de eliminação"
    end
  end

  def needs_location?
    self.sms and self.location.needs_location?
  end

  def sms_incomplete?
    self.sms and self.completed_at == nil
  end

  def self.invalidateExpired
    Report.where("created_at < ?", (Time.now - 3.days)).where(:status_cd => 0).each do |report|
      report.status_cd =1
      report.report = "This report has expired, it was not resolved within three days"
      report.save!
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

end
