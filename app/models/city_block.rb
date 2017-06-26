# -*- encoding : utf-8 -*-
class CityBlock < ActiveRecord::Base
  belongs_to :city
  belongs_to :district
  belongs_to :neighborhood

  has_many :locations

  validates_presence_of :name, :neighborhood_id, :district_id, :city_id
end
