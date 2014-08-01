class BreedingSite < ActiveRecord::Base
  attr_accessible :description_in_pt, :description_in_es

  #----------------------------------------------------------------------------

  has_many :elimination_methods, dependent: :destroy

  #----------------------------------------------------------------------------
  
end
