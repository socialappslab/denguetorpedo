# An inspection is a conceptual connection between a visit and an individual report.
# In other words, a visit has many reports though some inspection. Conversely,
# a report has many visits through several inspections.
#
# NOTE: The primary key is (report_id, visit_id).
# NOTE: Inspection times are defined in the associated report.
class Inspection < ActiveRecord::Base
  attr_accessible :visit_id, :report_id, :identification_type

  module Types
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
  end

  belongs_to :visit
  belongs_to :report
  validates_uniqueness_of :report_id, :scope => :visit_id
end
