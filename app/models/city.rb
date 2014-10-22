class City < ActiveRecord::Base
  attr_accessible :name, :photo, :state, :state_code, :country_id, :as => :admin

  belongs_to :country
  has_many   :neighborhoods

  #----------------------------------------------------------------------------

  validates :name,       :presence => true
  validates :state,      :presence => true
  validates :state_code, :presence => true
  validates :country_id, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo
  do_not_validate_attachment_file_type :photo

  #----------------------------------------------------------------------------

  def localized_country_name
    if self.country.name == Country::Names::MEXICO
      return I18n.t('countries.mexico')
    elsif self.country.name == Country::Names::NICARAGUA
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
