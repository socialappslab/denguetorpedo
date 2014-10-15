class AddTimeStampsToBreedingSites < ActiveRecord::Migration
  def change
    add_column    :breeding_sites, :created_at, :datetime
    add_column    :breeding_sites, :updated_at, :datetime
    remove_column :breeding_sites, :points

    BreedingSite.find_each do |bs|
      bs.created_at = Time.now
      bs.save
    end
  end
end
