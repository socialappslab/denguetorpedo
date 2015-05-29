# -*- encoding : utf-8 -*-
class UserNotification < ActiveRecord::Base
  attr_accessible :user_id, :notification_id, :notification_type, :medium, :seen_at, :notified_at

  #----------------------------------------------------------------------------

  module Mediums
    WEB   = 0
    EMAIL = 1
  end

  #----------------------------------------------------------------------------

  belongs_to :user

  #----------------------------------------------------------------------------

  validates :user_id,           :presence => true
  validates :notification_id,   :presence => true
  validates :notification_type, :presence => true
  validates :medium,            :presence => true
  validates :notified_at,       :presence => true

  #----------------------------------------------------------------------------
end
