namespace :cleanup do
  task :populate_inspections_with_reports => :environment do |t, args|
    Inspection.find_each do |inspection|
      report = inspection.report
      next if report.blank?

      next if inspection.description.present?
      next if inspection.breeding_site_id.present?

      puts "Looking at..."
      puts "inspection = #{inspection.inspect}\n\n"
      puts "\n\nReport: #{report.inspect}\n\n"

      if report.after_photo.blank?
        inspection.save_without_after_photo = true
      end

      if report.elimination_method_id.blank?
        inspection.save_without_elimination_method = true
      end

      inspection.description = report.report
      inspection.reporter_id = report.reporter_id
      inspection.created_at = report.created_at
      inspection.updated_at = report.updated_at
      inspection.eliminator_id = report.eliminator_id
      inspection.location_id = report.location_id
      inspection.before_photo = report.before_photo
      inspection.after_photo  = report.after_photo
      inspection.eliminated_at = report.eliminated_at
      inspection.inspected_at  = report.created_at
      inspection.breeding_site_id = report.breeding_site_id
      inspection.elimination_method_id = report.elimination_method_id
      inspection.csv_uuid = report.csv_uuid
      inspection.protected = report.protected
      inspection.chemically_treated = report.chemically_treated
      inspection.larvae = report.larvae
      inspection.pupae  = report.pupae
      inspection.field_identifier = report.field_identifier

      inspection.save!
    end
  end
end
