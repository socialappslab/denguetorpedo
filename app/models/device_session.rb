class DeviceSession < ActiveRecord::Base
  attr_accessible :user_id, :token

  belongs_to :user
end
