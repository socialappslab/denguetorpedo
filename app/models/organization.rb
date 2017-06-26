# -*- encoding : utf-8 -*-

class Organization < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :teams

  validates_presence_of :name
end
