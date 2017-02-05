# -*- encoding : utf-8 -*-

class UserLocation < ActiveRecord::Base
  attr_accessible :user_id, :location_id, :assigned_at, :source

  belongs_to :user
  belongs_to :location

  validates_presence_of :user_id
  validates_presence_of :location_id
end
