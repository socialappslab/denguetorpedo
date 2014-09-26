class EliminationMethod < ActiveRecord::Base
  belongs_to :elimination_type
  belongs_to :breeding_site

  validates :points, :presence => true
  validates_numericality_of :points

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
