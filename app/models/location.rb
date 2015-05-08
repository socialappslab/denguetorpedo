# -*- encoding : utf-8 -*-

class Location < ActiveRecord::Base
  attr_accessible :address, :street_type, :street_name, :street_number, :latitude, :longitude, :neighborhood_id

  #----------------------------------------------------------------------------

  validates :address,         :presence => true
  validates :neighborhood_id, :presence => true

  #----------------------------------------------------------------------------

  belongs_to :neighborhood
  has_many :reports, :dependent => :destroy
  has_many :visits,  :dependent => :destroy

  #----------------------------------------------------------------------------

  BASE_URI = "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates"

  #----------------------------------------------------------------------------

  # The hiearchy for choosing the address is as follows:
  # 1. address column,
  # 2. Concatenation of street_type, street_name, street_number columns,
  # 3. neighborhood column.
  def descriptive_address
    return self.address if self.address.present?

    if (self.street_type.present? && self.street_name.present? && self.street_number.present?)
      return self.street_type + " " + self.street_name + " " + self.street_number
    end

    return ""
  end

  #----------------------------------------------------------------------------

end
