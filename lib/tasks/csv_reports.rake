# encoding: UTF-8

#------
# NOTE: This is a one-time rake task that will place all
# existing users into Mare neighborhood.

namespace :csv_reports do
  desc "[One-off task] Backfill created_at date with house inspection date"
  task :backfill_created_at => :environment do


    CsvReport.find_each do |csv|
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

        begin
          puts "Looking at report with id = #{r.id}"
          puts "date: #{date} | parsed: #{DateTime.parse(date)}"
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
end
