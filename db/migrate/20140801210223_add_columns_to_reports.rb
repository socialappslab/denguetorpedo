class AddColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :breeding_site_id, :integer
    add_column :reports, :elimination_method_id, :integer

    Report.find_each do |r|
      puts "[ ] Updating breeding_site_id for report with id = #{r.id}"

      if r.elimination_type.present?
        # NOTE: We don't want to confuse elimination_method method with column.
        bs = BreedingSite.find_by_description_in_pt( r.attributes["elimination_type"] )
        r.breeding_site_id = bs.id
      end

      if r.elimination_method.present?
        # NOTE: We don't want to confuse elimination_method method with column.
        em = EliminationMethod.find_by_description_in_pt( r.attributes["elimination_method"] )
        r.elimination_method_id = em.id
      end

      r.save(:validate => false)

      puts "[ok] Done updating breeding_site_id for report with id = #{r.id}!"
    end


  end
end
