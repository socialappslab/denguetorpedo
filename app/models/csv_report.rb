class CsvReport < ActiveRecord::Base
  attr_accessible :csv
  has_attached_file :csv
  do_not_validate_attachment_file_type :csv

  has_many :reports
  belongs_to :user
end
