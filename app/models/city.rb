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

  #----------------------------------------------------------------------------


end
