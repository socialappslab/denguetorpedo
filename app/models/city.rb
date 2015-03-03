class City < ActiveRecord::Base
  attr_accessible :name, :photo, :state, :state_code, :time_zone, :as => :admin

  #----------------------------------------------------------------------------

  module Countries
    MEXICO    = "Mexico"
    BRAZIL    = "Brazil"
    NICARAGUA = "Nicaragua"
  end

  #----------------------------------------------------------------------------

  has_many   :neighborhoods

  #----------------------------------------------------------------------------

  validates :name,       :presence => true
  validates :state,      :presence => true
  validates :state_code, :presence => true
  validates :time_zone,  :presence => true

  # TODO: Deprecate this after March 1st, 2015
  validates :country, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo
  do_not_validate_attachment_file_type :photo

  #----------------------------------------------------------------------------

  def localized_country_name
    if self.country == Countries::MEXICO
      return I18n.t('countries.mexico')
    elsif self.country == Countries::NICARAGUA
      return I18n.t('countries.nicaragua')
    else
      return I18n.t('countries.brazil')
    end
  end

  def geographical_name
    return "#{self.name}, #{self.localized_country_name}"
  end

  #----------------------------------------------------------------------------

end
