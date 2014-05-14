# encoding: utf-8
require 'active_support/core_ext'

class Location < ActiveRecord::Base
  attr_accessible :address, :street_type, :street_name, :street_number, :latitude, :longitude
  # validates :latitude, :uniqueness => { :scope => :longitude }
  # validates :neighborhood_id, :presence => true

  has_one :house, dependent: :destroy
  belongs_to :neighborhood
  has_many :reports, dependent: :destroy

  before_save :save_address

  # This will trigger a background job if map coordinates
  # haven't been set yet.
  after_commit :update_map_coordinates, :on => :create

  BASE_URI = "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates"

  #----------------------------------------------------------------------------

  def save_address
    if self.address.nil?
      self.address = self.street_type + " " + self.street_name + " " + self.street_number
    end
  end

  #----------------------------------------------------------------------------

  def geocode(address = "")
    self.address = self.street_type + " " + self.street_name + " " + self.street_number
    uri = URI.parse(URI.escape("#{BASE_URI}?f=pjson&outSR=29193&Street=#{self.address}"))

    result = JSON.parse(Net::HTTP.get(uri))["candidates"].first

    if result
      self.latitude = result["location"]["x"]
      self.longitude = result["location"]["y"]
      [self.latitude.to_s, self.longitude.to_s]
    else
      self.latitude = nil
      self.longitude = nil
    end
  end

  #----------------------------------------------------------------------------

  def points
    house.nil? ? 0 : house.points
  end

  #----------------------------------------------------------------------------
  
  def complete_address
    # self.gmaps4rails_address
    # currently hardcoded....
    if self.street_type
      return self.street_type + " " + self.street_name + " " + self.street_number # + " " + "Maré"
    else
      return self.address
    end
  end

  #----------------------------------------------------------------------------

  def self.find_or_create(address, neighborhood=nil)
    # construct the Location object using the argument
    if address.class == String
      location = Location.new
      location.address = address
    elsif address.class <= Hash
      location = Location.new(address) # TODO: fix security issue...
    else
      return nil
    end

    # if the id argument is also passed, return the existing object that matches the id
    if location.id != nil
      existing_location = Location.find(location.id)
      return existing_location unless existing_location.nil?
    end

    location.neighborhood = Neighborhood.find_or_create_by_name(neighborhood)
    location.save!
    return location
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def update_map_coordinates
    return if self.latitude.present? && self.longitude.present?
    MapCoordinatesWorker.perform_async(self.id)
  end

  #----------------------------------------------------------------------------

end
