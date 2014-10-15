class CsvReport < ActiveRecord::Base
  # attr_accessibl

  belongs_to :report

  validates :report_id, :presence => true
end
