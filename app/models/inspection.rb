# -*- encoding : utf-8 -*-
# An inspection is a conceptual connection between a visit and an individual report.
# In other words, a visit has many reports though some inspection. Conversely,
# a report has many visits through several inspections.
#
# NOTE: The primary key is (report_id, visit_id).
# NOTE: Inspection times are defined in the associated report.
class Inspection < ActiveRecord::Base
  attr_accessible :visit_id, :report_id, :csv_id, :identification_type, :position, :report, :pupae, :created_at, :neighborhood_id, :breeding_site_id,
  :elimination_method_id, :before_photo, :after_photo, :status, :reporter_id,
  :location, :location_attributes, :breeding_site, :eliminator_id, :verifier_id,
  :location_id, :reporter, :sms, :is_credited, :credited_at, :completed_at,
  :verifier, :resolved_verifier, :eliminator, :eliminated_at, :csv_report_id,
  :protected, :chemically_treated, :larvae, :field_identifier



  module Types
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
  end


  #----------------------------------------------------------------------------
  # Constants

  EXPIRATION_WINDOW = 48 * 3600 # in seconds


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
  belongs_to :breeding_site
  belongs_to :elimination_method

  belongs_to :visit
  belongs_to :report
  belongs_to :spreadsheet, :foreign_key => "csv_id"

  # The following associations define all stakeholders in the reporting
  # process.
  belongs_to :reporter,    :class_name => "User"
  belongs_to :eliminator,  :class_name => "User"
  belongs_to :spreadsheet, :foreign_key => "csv_id"

  #----------------------------------------------------------------------------

  after_destroy :conditionally_destroy_visit

  def self.humanized_inspection_types
    {
      Types::POSITIVE  => "Positivo",
      Types::POTENTIAL => "Potencial",
      Types::NEGATIVE  => "Negativo"
    }
  end

  def self.color_for_inspection_status
    {
      Inspection::Types::POSITIVE  => "#e74c3c",
      Inspection::Types::POTENTIAL => "#f1c40f",
      Inspection::Types::NEGATIVE  => "#2ecc71"
    }
  end

  #----------------------------------------------------------------------------

  def conditionally_destroy_visit
    visit = Visit.find_by_id(self.visit_id)
    visit.destroy if visit && visit.inspections.count == 0
  end

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
end
