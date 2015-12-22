# -*- encoding : utf-8 -*-
# An inspection is a conceptual connection between a visit and an individual report.
# In other words, a visit has many reports though some inspection. Conversely,
# a report has many visits through several inspections.
#
# NOTE: The primary key is (report_id, visit_id).
# NOTE: Inspection times are defined in the associated report.
class Inspection < ActiveRecord::Base
  attr_accessible :visit_id, :report_id, :csv_id, :identification_type, :position

  module Types
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
  end

  belongs_to :visit
  belongs_to :report
  belongs_to :spreadsheet, :foreign_key => "csv_id"


  after_destroy :conditionally_destroy_visit

  def self.humanized_inspection_types
    {
      Types::POSITIVE  => "Positivo",
      Types::POTENTIAL => "Potencial",
      Types::NEGATIVE  => "Negativo"
    }
  end

  #----------------------------------------------------------------------------

  def conditionally_destroy_visit
    visit = Visit.find_by_id(self.visit_id)
    visit.destroy if visit.inspections.count == 0
  end

  #----------------------------------------------------------------------------
end
