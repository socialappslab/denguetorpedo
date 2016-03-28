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

  def self.permitted_params
    [:address, :neighborhood_id]
  end

  #----------------------------------------------------------------------------

  # This returns the so-called "house index" which can either be positive/potential
  # or without breeding sites.
  def inspection_types
    latest_visit = self.visits.order("visited_at DESC").limit(1).first
    return {Inspection::Types::POSITIVE => false, Inspection::Types::POTENTIAL => false, Inspection::Types::NEGATIVE => false} if latest_visit.blank?

    return latest_visit.inspection_types
  end

  # We define a green location as
  # a) having green status for at least 2 consecutive visits, and
  # b) the span of green visits is at least 2 months.
  def green?
    visits = self.visits.where("csv_id IS NOT NULL").order("visited_at DESC").map {|v| {:date => v.visited_at, :types => v.inspection_types} }
    return false if visits.blank?

    # Starting from the first index, let's see what the largest streak of
    # green visits is.
    green_streak = 0
    visits.each do |hash|
       break if hash[:types][Inspection::Types::NEGATIVE] == false
       green_streak += 1
     end

     # If the streak is 0, then the first visit is not green.
     # If the streak is 1, then the first visit is green, but not the second.
     return false if green_streak <= 1

     # At this point, we have at least 2 consecutive visits that are green. Let's
     # see if the span of all these visits is at least 2 months.
     span = visits[0][:date] - visits[green_streak - 1][:date]
     return (span >= 2.months.to_i)
  end

end
