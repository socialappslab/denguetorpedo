# encoding: UTF-8

#------------------------------------------------------------------------------

# NOTE: This is a one-time rake task that will populate
# all existing houses with the Mare neighborhood.

namespace :reports do
  task :update_cleaned_locations => :environment do
    Report.find_each do |r|
      next unless r.eliminated?
      next unless r.location.present?
      r.location.update_column(:cleaned, true)
    end
  end

  #----------------------------------------------------------------------------

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

  task :backfill_visits => :environment do
    Report.find_each do |r|
      puts "\n\n\n[ ] Creating an identification visit for report with id = #{r.id}...\n\n\n"

      r.create_inspection_visit()

      puts "\n\n\n[x] Created an identification visit for report with id = #{r.id}\n\n\n"
      puts "\n\n\n[ ] Creating a follow-up visit for report with id = #{r.id}\n\n\n"

      r.create_followup_visit()

      puts "\n\n\n[x] Created a follow-up visit for report with id = #{r.id}\n\n\n"
    end
  end

  #----------------------------------------------------------------------------

  # This is a one-off task that was created to change all reports created from
  # CSV that have breeding site P to check that they are indeed P or if they may
  # be the new breeding site B.
  task :separate_barrels_from_large_containers => :environment do

    # Some reports use an outdated CSV format which we have to go through manually.
    outdated_csv_uuids = []

    Report.find_each do |r|
      next if r.breeding_site_id.blank?
      next if r.csv_report_id.blank?

      # At this point, this report is associated with a CSV *and* its breeding
      # site is P. Let's check the corresponding row, and see if it's actually
      # P or B.
      matches = r.csv_uuid.match(/.*([a-z])[0-1][0-1][0-1][0-1]/i)

      if matches.nil?
        outdated_csv_uuids << "Report id (id=#{r.id}) has outdated format (csv uuid = #{r.csv_uuid})"
      elsif matches[1].downcase.strip == "b"
        bs = BreedingSite.find_by_code("B")
        r.update_column(:breeding_site_id, bs.id)
      end
    end

    puts "\n\n\noutdated_csv_uuids = #{outdated_csv_uuids}\n\n\n"
  end

  #----------------------------------------------------------------------------


end
