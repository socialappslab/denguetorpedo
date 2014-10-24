class EliminationMethod < ActiveRecord::Base
  belongs_to :elimination_type
  belongs_to :breeding_site

  #----------------------------------------------------------------------------

  validates :points, :presence => true
  validates_numericality_of :points

  validates :description_in_pt, :presence => :true
  validates :description_in_es, :presence => :true

  #----------------------------------------------------------------------------

  def description
    if I18n.locale == :es
      return self.description_in_es
    else
      return self.description_in_pt
    end

    return I18n.t("common_terms.not_available")
  end

  #----------------------------------------------------------------------------

  def detailed_description
    return self.description + " (#{self.points} #{I18n.t("attributes.points").downcase})"
  end

  #----------------------------------------------------------------------------


end
