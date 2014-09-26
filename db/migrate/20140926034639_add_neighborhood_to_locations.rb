class AddNeighborhoodToLocations < ActiveRecord::Migration
  def change
    # NOTE: This is distinct from neighborhood_id in the sense that
    # a user would use :neighborhood(string) to describe the location
    # of the report. The neighborhood_id is a pre-defined community
    # that DengueTorpedo operates in.
    add_column :locations, :neighborhood, :string
  end
end
