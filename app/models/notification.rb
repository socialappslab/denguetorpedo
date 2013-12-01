# == Schema Information
#
# Table name: notifications
#
#  id         :integer          not null, primary key
#  phone      :string(255)
#  text       :text
#  board      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  read       :boolean          default(FALSE)
#

class Notification < ActiveRecord::Base
  attr_accessible :board, :phone, :text
  scope :unread, where(read: false)
end
