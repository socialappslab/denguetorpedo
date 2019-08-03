class AddVerifierIdAndResolverVerifiedToInspections < ActiveRecord::Migration
  def change
    add_column :inspections, :verifier_id, :integer
    add_column :inspections, :resolved_verifier_id, :integer
  end
end
