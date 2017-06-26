# -*- encoding : utf-8 -*-
class District < ActiveRecord::Base
  belongs_to :city

  has_many :neighborhoods
  has_many :locations, :through => :neighborhoods

  validates_presence_of :name, :city_id
end
