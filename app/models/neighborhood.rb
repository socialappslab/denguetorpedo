# encoding: utf-8

class Neighborhood < ActiveRecord::Base
  attr_accessible :name, :photo, :city, :state_string_id, :country_string_id, :as => :admin

  #----------------------------------------------------------------------------

  module Names
    MARE       = "Maré"
    TEPALCINGO = "Tepalcingo"
  end

  #----------------------------------------------------------------------------

  has_many :locations

  # TODO: Deprecate houses association
  has_many :houses
  has_many :teams
  has_many :members, :class_name => "User"
  has_many :reports
  has_many :notices
  belongs_to :coordinator, :class_name => "User"
  has_many :health_agents, :through => :houses, :source => "members", :conditions => "is_health_agent = 1"

  #----------------------------------------------------------------------------

  validates :name,              :presence => true
  validates :city,              :presence => true
  validates :state_string_id,   :presence => true
  validates :country_string_id, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo, :styles => { :large => "400x400", :thumbnail => "150x150" }

  #----------------------------------------------------------------------------
  # Geographical data
  #------------------

  # NOTE: this method returns a Country object.
  def country
    return Country[self.country_string_id]
  end

  def state
    c = self.country
    return c.states[self.state_string_id]["name"]
  end

  #----------------------------------------------------------------------------

  def descriptive_name
    if I18n.locale == :es
      return I18n.t("attributes.neighborhood_id") + " de " + self.name
    else
      return I18n.t("attributes.neighborhood_id") + " " + self.name
    end
  end

  #----------------------------------------------------------------------------

  def geographical_name
    if self.country.name == "Mexico"
      return "#{self.name}, #{I18n.t('countries.mexico')}"
    else
      return "#{self.name}, #{I18n.t('countries.brazil')}"
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
