class Country < ActiveRecord::Base
  attr_accessible :name, :as => [:admin]

  #----------------------------------------------------------------------------

  has_many   :cities

  #----------------------------------------------------------------------------

  validates :name,       :presence => true

  #----------------------------------------------------------------------------

  module Names
    MEXICO    = "Mexico"
    BRAZIL    = "Brazil"
    NICARAGUA = "Nicaragua"
  end

end