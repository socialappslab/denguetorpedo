# encoding: UTF-8

#------------------------------------------------------------------------------

# NOTE: This is a one-time rake task that will populate
# all existing houses with the Mare neighborhood.

namespace :reports do
  desc "[One-off backfill task] Backfill reports with Maré neighborhood"
  task :backfill_with_mare_neighborhood => :environment do
    mare_neighborhood = Neighborhood.first

    Report.find_each do |r|
      next if r.neighborhood_id.present?
      r.update_attribute(:neighborhood_id, mare_neighborhood.id)
    end
  end

  #----------------------------------------------------------------------------

  task :populate_reports_with_breeding_sites => :environment do
    Report.find_each do |r|
      puts "[ ] Updating breeding_site_id for report with id = #{r.id}"

      if r.attributes["elimination_type"].present?
        # NOTE: We don't want to confuse elimination_method method with column.
        bs = BreedingSite.find_by_description_in_pt( r.attributes["elimination_type"] )
        raise "Could not find BreedingSite instance with description = #{r.attributes["elimination_type"]}" if bs.nil?
        r.breeding_site_id = bs.id
      end

      if r.attributes["elimination_method"].present?
        # NOTE: We don't want to confuse elimination_method method with column.
        em = EliminationMethod.find_by_description_in_pt( r.attributes["elimination_method"] )
        raise "Could not find EliminationMethod instance with description = #{r.attributes["elimination_method"]}" if em.nil?
        r.elimination_method_id = em.id
      end

      r.save(:validate => false)

      puts "[ok] Done updating breeding_site_id for report with id = #{r.id}!"
    end
  end

  #----------------------------------------------------------------------------

end
