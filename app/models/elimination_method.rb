class EliminationMethod < ActiveRecord::Base
  belongs_to :elimination_type
  belongs_to :breeding_site

  #----------------------------------------------------------------------------

  validates :points, :presence => true
  validates_numericality_of :points
  validate :description_in_locales

  #----------------------------------------------------------------------------

  before_save :set_locale_description

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

  private

  # We use this before_save callback to ensure that both description_in_pt *and*
  # description_in_es are set.
  def set_locale_description
    self.description_in_pt = self.description_in_es if self.description_in_pt.blank?
    self.description_in_es = self.description_in_pt if self.description_in_es.blank?
  end

  def description_in_locales
    if self.description_in_es.blank? && self.description_in_pt.blank?
      errors[:base] << "You need to supply a description in either Portuguese or Spanish (or both)"
    end
  end

  #----------------------------------------------------------------------------

end
