# -*- encoding : utf-8 -*-

class Neighborhood < ActiveRecord::Base
  attr_accessible :name, :photo, :city_id, :latitude, :longitude, :as => :admin

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

  has_many :teams
  has_many :members, :class_name => "User"
  has_many :users
  has_many :reports, :conditions => "completed_at IS NOT NULL"
  has_many :notices
  belongs_to :coordinator, :class_name => "User"
  has_many :posts

  # TODO: We no longer have houses so we may have to deprecate this.
  # has_many :health_agents, :through => :houses, :source => "members", :conditions => "is_health_agent = 1"

  #----------------------------------------------------------------------------

  validates :name,    :presence => true
  validates :city_id, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo, :styles => { :large => ["400x400", :jpg], :thumbnail => "150x150" }
  do_not_validate_attachment_file_type :photo

  #----------------------------------------------------------------------------
  # Geographical data
  #------------------

  def spanish?
    return [City::Countries::MEXICO, City::Countries::NICARAGUA].include?(self.country)
  end

  def mexican?
    return self.country == City::Countries::MEXICO
  end

  def brazilian?
    return self.country == City::Countries::BRAZIL
  end

  def nicaraguan?
    return self.country == City::Countries::NICARAGUA
  end

  def country
    return self.city.country
  end

  #----------------------------------------------------------------------------

  def geographical_display_name
    return self.name + ", " + self.city.name
  end

  def time_zone
    if self.mexican?
      return "America/Mexico_City"
    elsif self.nicaraguan?
      return "America/Guatemala"
    elsif brazilian?
      return "America/Sao_Paulo"
    end
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
    self.teams.sum(:points)
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
