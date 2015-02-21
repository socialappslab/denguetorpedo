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


  #----------------------------------------------------------------------------


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


  #----------------------------------------------------------------------------

  desc "[One-off task] Task that runs through the corrected CSV library, using a copy of CsvReportsController#create method to create CSV/Report/Location/Visit instances"
  task :upload_correct_data => :environment do
    csv_folder = Rails.root + "lib/tasks/corrected_csv_reports/la_quinta/".to_s
    hood = csv_folder.split[-1].to_s
    neighborhood = Neighborhood.all.find {|n| n.name.downcase.gsub(" ", "_").strip == hood.strip}

    raise "Neighborhood #{ neighborhood } not found!" if neighborhood.blank?

    user = User.find_by_username("dmitri")
    errors = []
    Dir[csv_folder + "*.xlsx"].each_with_index do |f, index|
      puts "-" * 50
      puts "[index=#{index}] Looking at file f = #{f.inspect}\n\n\n"
      csv      = File.open(f)
      csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      params = {
        :report_location_attributes_latitude => neighborhood.latitude.to_s,
        :report_location_attributes_longitude => neighborhood.longitude.to_s,
        :csv_report => {:csv => csv_file},
        :neighborhood_id => neighborhood.id.to_s
      }

      # begin
        create_csv_report(params, user)
      # rescue Exception => e
      #   errors << {"file" => f.to_s,"error" => e.to_s}
      # end



      puts "Done with file."
      puts "\n" * 10
      # break
    end

    puts "\n" * 20
    puts "Here are the errors:"
    puts "errors: #{errors}"

  end


  #----------------------------------------------------------------------------


  def create_csv_report(params, user)
    @neighborhood = Neighborhood.find(params[:neighborhood_id])
    @current_user = user

    # Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      raise I18n.t("views.csv_reports.flashes.missing_location")
    end

    # 2. Identify the file content type.
    file        = params[:csv_report][:csv]
    spreadsheet = CsvReport.load_spreadsheet( file )
    unless spreadsheet
      raise I18n.t("views.csv_reports.flashes.unknown_format")
    end

    # 3. Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = CsvReport.extract_address_from_spreadsheet(spreadsheet)
    if address.blank?
      raise I18n.t("views.csv_reports.flashes.missing_house")
    end

    # Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      raise I18n.t("views.csv_reports.flashes.missing_visits")
    end

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = CsvReport.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    rows.each do |row|
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      type = row_content[:breeding_site].strip.downcase
      if CsvReport.accepted_breeding_site_codes.exclude?(type)
        raise I18n.t("views.csv_reports.flashes.unknown_code")
      end
    end


    #-------------------------------------------------------------------
    # At this point, we have a non-trivial CSV with valid breeding codes.
    reports            = []
    visits             = []
    current_visited_at = nil
    parsed_current_visited_at = nil
    rows.each_with_index do |row, row_index|
      puts "Looking at row: #{row}"
      row_content = CsvReport.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      # Let's begin by creating a visit, if applicable.
      # Let's parse the current visited at date.
      # NOTE: If the last type is N then the location is clean (definition). However,
      # we don't have to keep track of it in some "status" key. Why? Because the visit
      # will have 0 reports, which is taken into account in visit.identification_type
      # method!
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at        = row_content[:visited_at]
        parsed_current_visited_at = Time.zone.parse( current_visited_at ) || Time.now

        if parsed_current_visited_at.future?
          puts "current_visited_at: #{current_visited_at} | parsed_current_visited_at: #{parsed_current_visited_at}"
          raise I18n.t("views.csv_reports.flashes.inspection_date_in_future")
        end


        visits << {
          :visited_at    => parsed_current_visited_at,
          :health_report => row_content[:health_report]
        }
      end


      # Build report attributes.
      uuid        = CsvReport.generate_uuid_from_row_index_and_address(row, row_index, address)
      description = CsvReport.generate_description_from_row_content(row_content)

      type = row_content[:breeding_site].strip.downcase
      if type == "a"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type == "b"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
      elsif type == "l"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
      elsif type == "m"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
      elsif type == "p"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
      elsif type == "t"
        breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
      end


      # Add to reports only if the code doesn't equal "negative" code.
      unless type == "n"
        eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

        # If the date of elimination is in the future or before visit date, then let's raise an error.
        if eliminated_at.present? && eliminated_at.future?
          raise I18n.t("views.csv_reports.flashes.elimination_date_in_future")
        end

        if eliminated_at.present? && eliminated_at < parsed_current_visited_at
          raise I18n.t("views.csv_reports.flashes.elimination_date_before_inspection_date")
        end

        reports << {
          :visited_at    => parsed_current_visited_at,
          :eliminated_at => eliminated_at,
          :breeding_site => breeding_site,
          :description   => description,
          :protected     => row_content[:protected],
          :chemically_treated => row_content[:chemical],
          :larvae => row_content[:larvae],
          :pupae => row_content[:pupae],
          :csv_uuid => uuid
        }
      end
    end

    #--------------------------------
    # Find and/or create the location.
    location = Location.find_by_address(address)
    if location.blank?
      location = Location.create!(:latitude => lat, :longitude => long, :address => address)
    end


    #-------------------------------
    # Create or update the CSV file.
    @csv_report = CsvReport.find_by_parsed_content(rows.to_json)
    if @csv_report.blank?
      @csv_report                = CsvReport.new
      @csv_report.csv            = file
      @csv_report.parsed_content = rows.to_json
      @csv_report.user_id        = @current_user.id
      @csv_report.location_id    = location.id
      @csv_report.save
    end


    #------------------------------
    # Create or update the reports.
    reports.each do |report|
      r = Report.find_by_csv_uuid(report[:csv_uuid])
      if r.blank?
        r            = Report.new
        r.created_at = report[:visited_at] if report[:visited_at].present?
      end

      r.report             = report[:description]
      r.breeding_site_id   = report[:breeding_site].id if report[:breeding_site].present?
      r.protected          = report[:protected]
      r.chemically_treated = report[:chemically_treated]
      r.larvae             = report[:larvae]
      r.pupae              = report[:pupae]
      r.location_id        = location.id
      r.neighborhood_id    = @neighborhood.id
      r.reporter_id        = @current_user.id
      r.csv_report_id      = @csv_report.id
      r.csv_uuid           = report[:csv_uuid]
      r.eliminated_at      = report[:eliminated_at]
      r.save(:validate => false)
    end

    #--------------------------------------------------------------------
    # The above Report callbacks create a set of visits and inspections. Here, we iterate
    # over our own set of visits, and either
    #
    # a) find existing visit with same date and set the health report,
    # b) create new visit (e.g. if it's of code N with no associated reports)
    #
    # We *must* run this here just so we can let the callbacks do their job.
    visits.each do |visit|
      parsed_visited_at = visit[:visited_at]

      ls = Visit.where(:location_id => location.id)
      ls = ls.where(:parent_visit_id => nil)
      ls = ls.where(:visited_at => (parsed_visited_at.beginning_of_day..parsed_visited_at.end_of_day))
      ls = ls.order("visited_at DESC").limit(1)
      if ls.blank?
        ls                 = Visit.new
        ls.parent_visit_id = nil
        ls.location_id     = location.id
        ls.visited_at      = parsed_visited_at
      else
        ls = ls.first
      end

      ls.health_report = visit[:health_report]
      ls.save
    end


  end


  #----------------------------------------------------------------------------


end
