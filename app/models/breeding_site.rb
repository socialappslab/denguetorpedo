class BreedingSite < ActiveRecord::Base
  attr_accessible :description_in_pt, :description_in_es

  #----------------------------------------------------------------------------

  has_many :elimination_methods, dependent: :destroy

  #----------------------------------------------------------------------------

  def description
    if I18n.locale == :es
      return self.description_in_es
    else
      return self.description_in_pt
    end
  end

  #----------------------------------------------------------------------------

end
