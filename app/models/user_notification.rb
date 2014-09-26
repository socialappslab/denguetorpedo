class UserNotification < ActiveRecord::Base
  attr_accessible :user_id, :notification_type, :viewed

  #----------------------------------------------------------------------------

  belongs_to :user

  #----------------------------------------------------------------------------

  module Types
    MESSAGE = 0
  end

  #----------------------------------------------------------------------------

  validates :user_id,           :presence => true
  validates :notification_type, :presence => true
end
