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

  task :create_organizations => :environment do |t|
    org = Organization.find_or_create_by(:name => "Instituto de Ciencias Sostenibles")
    User.find_each do |user|
      Membership.find_or_create_by(:user_id => user.id, :organization_id => org.id, :role => user.role, :blocked => user.is_blocked, :active => true)
    end

    org2 = Organization.find_or_create_by(:name => "AMOS")
  end

  task :associate_teams_to_org => :environment do |t|
    org = Organization.find_or_create_by(:name => "Instituto de Ciencias Sostenibles")
    Team.find_each do |team|
      team.update_column(:organization_id, org.id)
    end
  end

  task :populate_city_for_locations => :environment do
    Location.find_each do |loc|
      next if loc.city_id.present?
      puts "loc = #{loc.inspect}"
      loc.update_column(:city_id, loc.neighborhood.city_id)
    end
  end

  task :cleanup_districts => :environment do
    managua = City.find_by(:name => "Managua")

    bad_city_definition = City.find_by(:name => "Managua Distrito 3")
    d = District.find_or_create_by(:name => "Distrito 3", :city_id => managua.id)

    bad_city_definition.neighborhoods.find_each do |n|
      n.update_column(:city_id, managua.id)
      n.update_column(:district_id, d.id)
    end

    bad_city_definition.locations.find_each do |loc|
      loc.update_column(:city_id, managua.id)
      loc.update_column(:district_id, d.id)
    end

    bad_city_definition = City.find_by(:name => "Managua Distrito 6")
    d = District.find_or_create_by(:name => "Distrito 6", :city_id => managua.id)

    bad_city_definition.neighborhoods.find_each do |n|
      n.update_column(:city_id, managua.id)
      n.update_column(:district_id, d.id)
    end

    bad_city_definition.locations.find_each do |loc|
      loc.update_column(:city_id, managua.id)
      loc.update_column(:district_id, d.id)
    end
  end
end
