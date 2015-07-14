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

end
