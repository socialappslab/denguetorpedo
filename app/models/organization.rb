# -*- encoding : utf-8 -*-

class Organization < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :teams
  has_many :organization_elimination_method, class_name: "OrganizationEliminationMethod"
  validates_presence_of :name
end
