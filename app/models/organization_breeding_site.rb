class OrganizationBreedingSite < ActiveRecord::Base

  self.table_name = "organizations_breeding_sites"
  attr_accessible :organization_id, :breeding_site_id

  belongs_to :organization
  belongs_to :breeding_site

  validates_presence_of :organization_id
  validates_presence_of :breeding_site_id

  scope :by_organization_code, -> organization_id, code { where("organization_id = ? AND code LIKE ?", "#{organization_id}", "#{code}") }
  

end
