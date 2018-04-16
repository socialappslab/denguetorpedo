# -*- encoding : utf-8 -*-

class Organization < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships
  has_many :teams
  has_many :organizations_breeding_sites, class_name: "OrganizationBreedingSite"

  validates_presence_of :name
end
