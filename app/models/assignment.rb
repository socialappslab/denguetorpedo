class Assignment < ActiveRecord::Base
  belongs_to :city_block
  has_and_belongs_to_many :users


end
