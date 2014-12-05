class DeviceSession < ActiveRecord::Base
  attr_accessible :user_id, :token

  validates :user_id,  :presence => true
  validates :token, :presence => true

  belongs_to :user
end
