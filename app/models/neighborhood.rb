# encoding: utf-8

class Neighborhood < ActiveRecord::Base
  attr_accessible :name, :photo, :city_id, :as => :admin

  #----------------------------------------------------------------------------

  module Names
    MARE           = "Maré"
    TEPALCINGO     = "Tepalcingo"
    OCACHICUALLI   = "Ocachicualli"
    FRANCISCA_MEZA = "Francisco Meza"
    HIALEAH        = "Hialeah"
    ARIEL_DARCE    = "Ariel Darce"
  end

  #----------------------------------------------------------------------------

  has_many :locations
  belongs_to :city

  # TODO: Deprecate houses association
  has_many :houses
  has_many :teams
  has_many :members, :class_name => "User"
  has_many :users
  has_many :reports
  has_many :notices
  belongs_to :coordinator, :class_name => "User"
  has_many :health_agents, :through => :houses, :source => "members", :conditions => "is_health_agent = 1"

  #----------------------------------------------------------------------------

  validates :name,    :presence => true
  validates :city_id, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo, :styles => { :large => "400x400", :thumbnail => "150x150" }

  #----------------------------------------------------------------------------
  # Geographical data
  #------------------

  def spanish?
    return [Country::Names::MEXICO, Country::Names::NICARAGUA].include?(self.country.name)
  end

  def mexican?
    return self.country.name == "Mexico"
  end

  def brazilian?
    return self.country.name == "Brazil"
  end

  def nicaraguan?
    return self.country.name == "Nicaragua"
  end

  def country
    return self.city.country
  end

  #----------------------------------------------------------------------------

  def geographical_name
    return "#{self.name}, #{self.city.name}"
  end

  #----------------------------------------------------------------------------

  # TODO: Deprecate this.
  def total_reports
    return self.reports.to_a
  end

  def open_reports
    return self.reports.find_all{ |r| r.open? }
  end

  def eliminated_reports
    return self.reports.find_all{ |r| r.eliminated? }
  end

  #----------------------------------------------------------------------------

  def total_points
    self.members.sum(:total_points)
  end

  #----------------------------------------------------------------------------

  def picture
    if self.photo_file_name.nil?
      return "neighborhoods/default.png"
    end

    return self.photo.url(:large)
  end


  #----------------------------------------------------------------------------

end
