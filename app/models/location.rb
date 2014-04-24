# encoding: utf-8
require 'active_support/core_ext'

class Location < ActiveRecord::Base
  attr_accessible :address, :street_type, :street_name, :street_number, :latitude, :longitude
  # acts_as_gmappable :callback => :geocode_results, :validation => true
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

  def neighborhood_name
    self.neighborhood && self.neighborhood.name
  end

  #----------------------------------------------------------------------------

  def geocode_results(data)
    # reset all these fields so we can extract it from the geocoding data
    self.nation = nil
    self.state = nil
    self.city = nil
    self.address = nil

    components = {}
    for c in data["address_components"]
      for t in c["types"]
        components[t] = c["long_name"]
      end
    end

    self.nation = components["country"]
    self.state = components["administrative_area_level_1"]
    self.city = components["locality"] || components["administrative_level_3"] || components["administrative_level_2"]
    self.address = "#{components['street_number']} #{components['route']}"
    self.formatted_address = data["formatted_address"]
  end

  def self.within_bounds(bounds)
      self.where(:location.within => {"$box" => bounds })
  end

  def points
    house.nil? ? 0 : house.points
  end

  def complete_address
    # self.gmaps4rails_address
    # currently hardcoded....
    if self.street_type
      return self.street_type + " " + self.street_name + " " + self.street_number + " " + "Maré"
    else
      return self.address
    end
  end

  def info
    {x: self.latitude, y: self.longitude, id: self.id, address: self.complete_address }
  end

  def needs_location?
    !(self.latitude && self.longitude)
  end

  def self.new_with_address(address)
    location = Location.new(address: address)
    # streets = location.address.split(' ') if location.address
    # if streets.size  >= 3
    #   location.street_type = streets[0]
    #   location.street_number = streets[streets.size - 1]
    #   location.street_name = streets[1..streets.size-2].join(' ')
    # end
    location.save
    return location
  end

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
