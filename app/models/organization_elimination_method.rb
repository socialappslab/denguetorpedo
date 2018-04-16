class OrganizationEliminationMethod < ActiveRecord::Base
    self.table_name = "organization_elimination_methods"
    belongs_to :elimination_method
    belongs_to :organization
    validates_presence_of :elimination_method_id, :organization_id
    attr_accessible :elimination_method, :organization_id, :code, :description
end
