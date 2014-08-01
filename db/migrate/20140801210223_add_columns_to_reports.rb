class AddColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :breeding_site_id, :integer
    add_column :reports, :elimination_method_id, :integer

    Report.find_each do |r|
      puts "[ ] Updating breeding_site_id for report with id = #{r.id}"

      if r.elimination_type.present?
        bs = BreedingSite.find_by_description_in_pt( r.elimination_type )
        r.breeding_site_id = bs.id
      end

      if r.elimination_method.present?
        em = EliminationMethod.find_by_description_in_pt( r.elimination_method )
        r.elimination_method_id = em.id
      end

      r.save!

      puts "[ok] Done updating breeding_site_id for report with id = #{r.id}!"
    end


  end
end
