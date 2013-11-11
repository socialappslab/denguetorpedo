class Notification < ActiveRecord::Base
  attr_accessible :board, :phone, :text
  scope :unread, where(read: false)
end
