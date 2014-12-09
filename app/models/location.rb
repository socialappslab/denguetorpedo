# encoding: utf-8
require 'active_support/core_ext'

class Location < ActiveRecord::Base
  attr_accessible :address, :street_type, :street_name, :street_number, :latitude, :longitude, :neighborhood, :neighborhood_id, :cleaned
  # validates :latitude, :uniqueness => { :scope => :longitude }
  # validates :neighborhood_id, :presence => true

  has_many :reports, dependent: :destroy
  has_many :location_statuses, :dependent => :destroy

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

  # The status of a location defines whether it's positive, potential, negative
  # or clean. The first three are defined by the associated reports at that
  # location, and the last one is separately set in the database. See the
  # 'status' instance method.
  module Status
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
    CLEAN     = 3
  end

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

  # The status of a location defines whether it's a positive, potential, or negative.
  def status
    reports         = self.reports
    positive_count  = reports.find_all {|r| r.status == Report::Status::POSITIVE}.count
    negative_count  = reports.find_all {|r| r.status == Report::Status::NEGATIVE}.count

    return Status::POSITIVE  if positive_count > 0
    return Status::NEGATIVE  if negative_count > 0
    return Status::POTENTIAL
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
