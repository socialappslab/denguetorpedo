class BreedingSite < ActiveRecord::Base
  attr_accessible :description_in_pt, :description_in_es, :elimination_methods_attributes

  #----------------------------------------------------------------------------

  has_many :elimination_methods, :dependent => :destroy
  accepts_nested_attributes_for :elimination_methods, :allow_destroy => true

  #----------------------------------------------------------------------------

  validates :description_in_pt, :presence => :true
  validates :description_in_es, :presence => :true

  #----------------------------------------------------------------------------

  def description
    if I18n.locale == :es
      return self.description_in_es if self.description_in_es.present?
    else
      return self.description_in_pt if self.description_in_pt.present?
    end

    return I18n.t("common_terms.not_available")
  end

  #----------------------------------------------------------------------------

  module Types
    DISH            = "dish"
    LARGE_CONTAINER = "large-containers"
    SMALL_CONTAINER = "small-containers"
    TIRE            = "tire"
    OTHER           = "other"
  end

end
