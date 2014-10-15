class CsvReport < ActiveRecord::Base
  attr_accessible :csv
  has_attached_file :csv
end
