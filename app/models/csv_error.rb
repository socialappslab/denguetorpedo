# -*- encoding : utf-8 -*-
require "roo"

class CsvError < ActiveRecord::Base
  attr_accessible :csv_report_id, :error_type

  #----------------------------------------------------------------------------

  belongs_to :csv_report

  #----------------------------------------------------------------------------

  validates :csv_report_id, :presence => true
  validates :error_type,    :presence => true

  #----------------------------------------------------------------------------

  module Errors
    MISSING_HOUSE                      = 0
    MISSING_VISITS                     = 1
    UNKNOWN_BREEDING_SITE_CODE         = 2
    VISIT_DATE_IN_FUTURE               = 3
    ELIMINATION_DATE_IN_FUTURE         = 4
    ELIMINATION_DATE_BEFORE_VISIT_DATE = 5
  end

  #----------------------------------------------------------------------------

end
