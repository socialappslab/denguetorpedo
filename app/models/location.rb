# encoding: utf-8
require 'active_support/core_ext'

class Location < ActiveRecord::Base
  attr_accessible :address, :street_type, :street_name, :street_number, :latitude, :longitude, :neighborhood
  # validates :latitude, :uniqueness => { :scope => :longitude }
  # validates :neighborhood_id, :presence => true

  has_one :house, dependent: :destroy
  has_many :reports, dependent: :destroy

  # NOTE: We already have a 'neighborhood' column in locations, so
  # we'll use community as the association on neighborhood_id.
  belongs_to :community, :foreign_key => :neighborhood_id

  # before_save :save_address

  # This will trigger a background job if map coordinates
  # haven't been set yet.
  # TODO: Re-enable this when we actually purchase a Heroku worker dyno.
  # after_commit :update_map_coordinates, :on => :create

  BASE_URI = "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates"

  #----------------------------------------------------------------------------

  # TODO: Deprecate this since we actually want to know when the :address
  # is left empty, and when it's not. As we move forward, we will deprecate
  # street_* columns, and can retroactively run a rake task to do this sort
  # of stuff this method is doing.
  # def save_address
  #   if self.address.nil?
  #     self.address = self.street_type + " " + self.street_name + " " + self.street_number
  #   end
  # end

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

  # TODO: Deprecate this method in favor of descriptive_address
  def complete_address
    # self.gmaps4rails_address
    # currently hardcoded....
    if self.street_type
      return self.street_type + " " + self.street_name + " " + self.street_number # + " " + "Maré"
    else
      return self.address
    end
  end

  # The hiearchy for choosing the address is as follows:
  # 1. address column,
  # 2. Concatenation of street_type, street_name, street_number columns,
  # 3. neighborhood column.
  def descriptive_address
    return self.address if self.address.present?

    if (self.street_type.present? && self.street_name.present? && self.street_number.present?)
      return self.street_type + " " + self.street_name + " " + self.street_number
    end

    return self.attributes["neighborhood"] if self.attributes["neighborhood"].present?
    return ""
  end

  #----------------------------------------------------------------------------

  # TODO: Complete deprecate this as this makes too many
  # assumptions about what user input and pre-existing locations...
  # def self.find_or_create(address, neighborhood=nil)
  #   # construct the Location object using the argument
  #   if address.class == String
  #     location = Location.new
  #     location.address = address
  #   elsif address.class <= Hash
  #     location = Location.new(address) # TODO: fix security issue...
  #   else
  #     return nil
  #   end
  #
  #   # if the id argument is also passed, return the existing object that matches the id
  #   if location.id != nil
  #     existing_location = Location.find(location.id)
  #     return existing_location unless existing_location.nil?
  #   end
  #
  #   location.neighborhood_id = Neighborhood.find_or_create_by_name(neighborhood).id
  #   location.save!
  #   return location
  # end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def update_map_coordinates
    return if self.latitude.present? && self.longitude.present?
    MapCoordinatesWorker.perform_async(self.id)
  end

  #----------------------------------------------------------------------------

end
