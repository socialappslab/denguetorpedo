# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will place all
# existing users into Mare neighborhood.

namespace :csv_reports do
  desc "[One-off task] Backfill created_at date with house inspection date"
  task :backfill_created_at => :environment do


    CsvReport.find_each do |csv|
      begin
        spreadsheet = load_spreadsheet( csv.csv )
      rescue
        puts "Couldn't open csv: #{csv.inspect}. \n\n\nSkipping...\n\n\n"
        next
      end

      start_index = 2
      while spreadsheet.row(start_index)[0].blank?
        start_index += 1
      end
      header  = spreadsheet.row(start_index)
      header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }

      address = spreadsheet.row(1)[1]
      address = address.to_s

      current_row = 0
      (start_index + 1..spreadsheet.last_row).each do |i|
        row            = Hash[[header, spreadsheet.row(i)].transpose]
        current_row   += 1

        # 4a. Extract the attributes. NOTE: We use fuzzy matching instead of
        # exact matching since users may vary the columns slightly.
        date           = row.select {|k,v| k.include?("fecha")}.values[0].to_s
        room           = row["localización"].to_s
        type           = row.select {|k,v| k.include?("tipo")}.values[0].to_s
        is_protected   = row['protegido'].to_i
        is_pupas       = row["pupas"].to_i
        is_larvas      = row["larvas"].to_i
        is_chemical     = row["abatizado"].to_i
        elim_date      = row.select {|k,v| k.include?("eliminado")}.values[0].to_s
        comments       = row.select {|k,v| k.include?("comentarios")}.values[0].to_s


        # 4b. Attempt to identify the breeding sites from the codes. If no type
        # is identified, then simply skip the whole row.
        next if type.blank?
        type = type.strip.downcase
        uuid = (address + date + room + type + is_protected.to_s + is_pupas.to_s + is_larvas.to_s + is_chemical.to_s)
        uuid = uuid.strip.downcase.underscore

        r = Report.find_by_csv_uuid(uuid)
        next if r.blank?

        begin
          puts "Looking at report with id = #{r.id}"
          puts "date: #{date}"
          puts "\n\n\n"

          # NOTE: We want the location status of the report to trigger *on the
          # inspection date*. In order to accomplish this, we will overwrite
          # the updated_at column of the report. This will either create a
          # new location status or update an existing one with the new status.
          # Consequently, this will alter *past* location statuses.
          r.created_at = DateTime.parse(date)
          r.updated_at = DateTime.parse(date)
          r.save(:validate => false)
        rescue
          puts "Failed to parse date = #{date}"
        end

        puts "-" * 50
      end
    end
  end

  desc "[One-off backfill task] Backfill users with Maré neighborhood"
  task :backfill_location_status => :environment do

    CsvReport.find_each do |csv|
      location = csv.location
      next if location.blank?

      spreadsheet = load_spreadsheet( csv.csv )
      start_index = 2
      while spreadsheet.row(start_index)[0].blank?
        start_index += 1
      end
      header  = spreadsheet.row(start_index)
      header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }

      address = spreadsheet.row(1)[1]
      address = address.to_s

      current_row = 0
      (start_index + 1..spreadsheet.last_row).each do |i|
        row            = Hash[[header, spreadsheet.row(i)].transpose]
        current_row   += 1

        # 4a. Extract the attributes. NOTE: We use fuzzy matching instead of
        # exact matching since users may vary the columns slightly.
        date           = row.select {|k,v| k.include?("fecha")}.values[0].to_s
        room           = row["localización"].to_s
        type           = row.select {|k,v| k.include?("tipo")}.values[0].to_s
        is_protected   = row['protegido'].to_i
        is_pupas       = row["pupas"].to_i
        is_larvas      = row["larvas"].to_i
        is_chemical     = row["abatizado"].to_i
        elim_date      = row.select {|k,v| k.include?("eliminado")}.values[0].to_s
        comments       = row.select {|k,v| k.include?("comentarios")}.values[0].to_s


        # 4b. Attempt to identify the breeding sites from the codes. If no type
        # is identified, then simply skip the whole row.
        next if type.blank?
        type = type.strip.downcase
        uuid = (address + date + room + type + is_protected.to_s + is_pupas.to_s + is_larvas.to_s + is_chemical.to_s)
        uuid = uuid.strip.downcase.underscore

        r = Report.find_by_csv_uuid(uuid)
        next if r.blank?

        r.protected = is_protected
        r.chemically_treated = is_chemical
        r.larvae = is_larvas
        r.pupae  = is_pupas
        r.save(:validate => false)
      end
    end


  end


  def load_spreadsheet(file)
    if File.extname( file.original_filename ) == ".csv"
      spreadsheet = Roo::CSV.new(file.url, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xls"
      spreadsheet = Roo::Excel.new(file.url, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file.url, :file_warning => :ignore)
    end

    return spreadsheet
  end


  task :destroy_incorrect_nicaragua_data => :environment do
    csv_ids = []

    start_time = Time.parse("2014-11-01").beginning_of_day
    end_time   = Time.now.end_of_day
    CsvReport.order("id ASC").where(:created_at => start_time..end_time).find_each do |csv|
      # puts "csv.location_id.blank?: #{csv.location_id.blank?} | csv.location.neighborhood.blank?: #{csv.location.neighborhood.blank?} | csv.location.neighborhood.nicaraguan?: #{csv.location.neighborhood.nicaraguan?}"
      next if csv.location_id.blank?
      next if csv.location.neighborhood_id.blank?
      neighborhood = Neighborhood.find(csv.location.neighborhood_id)
      next unless neighborhood.nicaraguan?

      # At this point, we only have a Nicaraguan CSV. Let's append it to our list.
      csv_ids << csv.id
    end
    csv_ids.uniq!

    # Let's identify all reports associated with the CSV ids.
    report_ids = Report.order("id ASC").where(:csv_report_id => csv_ids).pluck(:id)
    report_ids.uniq!

    # Now let's iterate over all locations, identifying the locations whose reports are *all*
    # in the set of identified reports. Otherwise, a location shouldn't be deleted.
    location_ids = []
    Location.order("id ASC").find_each do |l|
      location_report_ids = l.reports.pluck(:id)

      # If report_ids contains all ids of location_report_ids, then we know
      # that this location's reports are all of the affected reports. Let's delete
      # this location as well.
      if (location_report_ids - report_ids).empty?
        location_ids += location_report_ids
      end
    end

    location_ids.uniq!

    # Finally, let's identify visit that have the specified locations *and* occurred between
    # November 1st and February 20th.
    visit_ids = Visit.order("id ASC").where(:visited_at => start_time..end_time).where(:location_id => location_ids).pluck(:id)
    visit_ids.uniq!

    puts "\n" * 50
    puts "-"  * 50
    puts "Here is an array of CSV ids that are from Nicaragua (November 1st to February 20th): "
    puts "csv_ids: #{csv_ids}"
    puts "-"  * 50
    puts "report_ids: #{report_ids}"
    puts "-"  * 50
    puts "location_ids: #{location_ids}"
    puts "-"  * 50
    puts "visit_ids: #{visit_ids}"
    puts "\n" * 50
    puts "Now, do the following:"
    puts "* Destroy visits"
    puts "* Destroy locations"
    puts "* Destroy reports"
    puts "* Destroy csvs"
  end
end
