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

  module Types
    MISSING_HOUSE                      = 0
    MISSING_VISITS                     = 1
    UNKNOWN_CODE         = 2
    VISIT_DATE_IN_FUTURE               = 3
    ELIMINATION_DATE_IN_FUTURE         = 4
    ELIMINATION_DATE_BEFORE_VISIT_DATE = 5
    UNKNOWN_FORMAT = 6
  end

  #----------------------------------------------------------------------------

  def self.humanized_errors
    return {
      Types::MISSING_HOUSE => I18n.t("views.csv_reports.flashes.missing_house"),
      Types::MISSING_VISITS => I18n.t("views.csv_reports.flashes.missing_visits"),
      Types::UNKNOWN_CODE => I18n.t("views.csv_reports.flashes.unknown_code"),
      Types::VISIT_DATE_IN_FUTURE => I18n.t("views.csv_reports.flashes.inspection_date_in_future"),
      Types::ELIMINATION_DATE_IN_FUTURE => I18n.t("views.csv_reports.flashes.elimination_date_in_future"),
      Types::ELIMINATION_DATE_BEFORE_VISIT_DATE => I18n.t("views.csv_reports.flashes.elimination_date_before_inspection_date"),
      Types::UNKNOWN_FORMAT => I18n.t("views.csv_reports.flashes.unknown_format")
    }
  end

end
