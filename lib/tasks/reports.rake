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
        # NOTE: It looks like the database on staging (production not tested),
        # has been corrupted. I've decided to just not set the breeding site
        # if the elimination type can't be found.
        # if etype == "Pequenos Recipientes utilizáveis"
        #   etype = "Pequenos Recipientes utilizáveis Garrafas de vidro, vasos, baldes, tigela de água de cachorro"
        # elsif etype == "Grandes Recipientes Utilizáveis"
        #   etype = "Grandes Recipientes Utilizáveis Tonéis, outras depósitos de água, pias, galões d’água."
        # elsif etype == "Caixa d'água aberta na residência"
        #   etype = "Registros abertos"
        # end
        bs = BreedingSite.find_by_description_in_pt( r.attributes["elimination_type"] )
        r.breeding_site_id = bs.id if bs.present?
      end

      if r.attributes["elimination_method"].present?
        # NOTE: We don't want to confuse elimination_method method with column.
        em = EliminationMethod.find_by_method( r.attributes["elimination_method"] )
        r.elimination_method_id = em.id if em.present?
      end

      r.save(:validate => false)

      puts "[ok] Done updating breeding_site_id for report with id = #{r.id}!"
    end
  end

  #----------------------------------------------------------------------------

end
