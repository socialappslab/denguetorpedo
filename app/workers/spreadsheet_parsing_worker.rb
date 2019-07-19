require "sidekiq"

class SpreadsheetParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform(csv_id)
    # Make sure that we're parsing relative to the correct timezone.
    Rails.logger.info "Parsing of CSV started. Loading existing CSV with ID: #{csv_id}"
    Time.zone = "America/Guatemala"

    @csv   = Spreadsheet.find_by_id(csv_id)
    return if @csv.blank?
    Rails.logger.info "CSV was found..."

    # Reset any verification we may have done.
    @csv.verified_at = nil

    location      = @csv.location
    @neighborhood = location.neighborhood
    address       = location.address

    # Identify the file content type.
    spreadsheet = Spreadsheet.load_spreadsheet( @csv.csv )
    unless spreadsheet
      Rails.logger.info "Error while parsing of CSV #{csv_id}: Spreadsheet not loaded, Unknown format..."
      CsvError.create(:csv_id => @csv.id, :error_type => CsvError::Types::UNKNOWN_FORMAT)
      return
    end

    # Error out if there are no reports extracted.
    rows = Spreadsheet.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      Rails.logger.info "Error while parsing of CSV #{csv_id}: Missing Visits..."
      CsvError.create(:csv_id => @csv.id, :error_type => CsvError::Types::MISSING_VISITS)
      return
    end

    Rails.logger.info "No errors loading the CSV into a Spreadsheet. Loaded #{rows.length}"
    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = Spreadsheet.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    @csv.check_for_breeding_site_errors(rows)

    Rails.logger.info "No errors in breeding sites..."
    # Iterate over the rows, checking if any dates are invalid.
    @csv.check_for_date_errors(rows)

    Rails.logger.info "No errors in dates..."
    # If there are any errors, we can't proceed so let's offload right now and let
    # the user re-upload when they've fixed the errors.
    return if @csv.csv_errors.present?

    Rails.logger.info "No errors in spreadsheet..."
    #--------------------------------------------------------------------------
    # Let's iterate over the rows and create/update reports.
    #------

    # Create a User Location corresponding to this user.
    ul = UserLocation.find_by_user_id_and_location_id(@csv.user_id, location.id)
    if ul.blank?
      Rails.logger.info "User locaitn is blank, creating a new one..."
      ul = UserLocation.create(:user_id => @csv.user_id, :location_id => location.id, :source => "csv", :assigned_at => Time.zone.now)
    end

    # At this point, we do not have any errors. Let's iterate over each row, and
    # create/update the reports accordingly.
    current_visited_at = nil
    Rails.logger.info "Starting to parse the spreadsheet (rows = #{rows.length})"
    rows.each_with_index do |row, row_index|
      Rails.logger.info "Parsing row #{row_index}/#{rows.length}"
      row_content = Spreadsheet.extract_content_from_row(row)

      # Let's begin by creating a visit, if applicable. We create a visit
      # anytime there is an entry in visited_at column and that entry doesn't match
      # the last parsed entry.
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at = Time.zone.parse( row_content[:visited_at] )
        v = Visit.find_or_create_visit_for_location_id_and_date(location.id, current_visited_at)
        Rails.logger.info "Visit created/found #{v.visited_at} (#{v.id})"
        v.update_column(:health_report, row_content[:health_report])
        questions_content = row_content[:questions].nil? || "[]"
        v.update_column(:questions, questions_content)
        v.update_column(:source, @csv.source)
        v.update_column(:csv_id, @csv.id)
      end

      # Why do this? The specific bug here was that a valid visit date was completely ignored
      # because the row didn't have a breeding site. The correct solution is to
      # parse and store the visit date, and then make a decision on whether to
      # continue parsing the remaining columns.
      next if row_content[:breeding_site].blank?
      Rails.logger.info "Processing breeding sites: #{row_content[:breeding_site]}"

      # If the breeding code is N or X then we will NOT create a report. Otherwise,
      # we will, *and* we may also add a unique identifier to the report.
      raw_breeding_code = row_content[:breeding_site].strip.downcase
      # next if Spreadsheet.clean_breeding_site_codes.include?(raw_breeding_code)

      # At this point, we have a valid breeding code. Let's parse and start creating
      # the report.
      uuid          = Spreadsheet.generate_uuid_from_row_index_and_address(row, row_index, address)

      description   = row_content[:description]
      if (description.nil? || description == "")
        Spreadsheet.generate_description_from_row_content(row_content)
      end
      breeding_site = Spreadsheet.extract_breeding_site_from_row(row_content)

      # We say that the report has a field identifier if the breeding site CSV column
      # also has an integer associated with it.
      field_id = nil
      field_id = raw_breeding_code if raw_breeding_code =~ /\d/

      # Add to reports only if the code doesn't equal "negative" code.
      # ToDo: if same breeding site code is found in the same location in subsequent visits
      # can we consider them to be the same?
      eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

      reporter_user_id = Spreadsheet.extract_user_id_from_row(row_content)
      # ToDo: add team to inspections
      reporter_team_id = Spreadsheet.extract_team_id_from_row(row_content)

      # Create an inspection regardless if eliminated_at is present or not. This
      # ensures that we have a 1-1 correspondence between a row and an inspection.
      # find_or_create_visit_and_inspection(@csv, current_visited_at, r)
      v = Visit.find_or_create_visit_for_location_id_and_date(@csv.location_id, current_visited_at)
      v.update_column(:csv_id, @csv.id)
      Rails.logger.info "Creating visit for location and date: #{@csv.location_id}, #{current_visited_at}"

      if Spreadsheet.clean_breeding_site_codes.include?(raw_breeding_code)
        ins                    = Inspection.new
        ins.inspected_at       = current_visited_at
        ins.identification_type = Inspection::Types::NEGATIVE
        ins.location_id        = location.id
        ins.reporter_id        = reporter_user_id.nil? ? @csv.user_id : reporter_user_id
        ins.csv_id             = @csv.id
        ins.position           = @csv.inspections.count
        ins.save(:validate => false)
        next
      end



      # We only update existing inspections if eliminated_at property is present.
      # Otherwise, let's create a new inspection.
      ins = @csv.inspections.find_by(:field_identifier => field_id, :visit_id => v.id) if field_id.present?
      if ins.blank?
        # At this point, this isn't a report with a field identifier. Because
        # we're parsing the whole CSV, there are two options:
        # 1. This report has been previously created from a previous upload.
        #    In this case, we should be able to identify it through the UUID. The
        #    only attributes we should update is whether it has been eliminated,
        #    which we do further down.
        # 2. The other possibility is that this is a new report. In this case, we
        #    create it with all attributes, and leave the checking of eliminated_at
        #    further down.
        ins = @csv.inspections.find_by_csv_uuid(uuid)
        if ins.blank?
          ins                    = Inspection.new
          ins.field_identifier   = field_id
          ins.inspected_at       = current_visited_at
          ins.description        = description
          ins.breeding_site_id   = breeding_site.id if breeding_site.present?
          ins.protected          = row_content[:protected]
          ins.chemically_treated = row_content[:chemical]
          ins.larvae             = row_content[:larvae]
          ins.pupae               = row_content[:pupae]
          ins.identification_type = ins.original_status
          ins.location_id        = location.id
          ins.reporter_id        = reporter_user_id.nil? ? @csv.user_id : reporter_user_id
          ins.source             = @csv.source
          ins.csv_id             = @csv.id
          ins.csv_uuid           = uuid
          ins.position           = @csv.inspections.count
          ins.save(:validate => false)
        end
      end

      if ins.present?
        ins.visit_id = v.id
        ins.csv_id   = @csv.id
        ins.identification_type = ins.original_status
        ins.position = @csv.inspections.count
        ins.save(:validate => false)
      end

      # At this point,
      if eliminated_at.present?
        ins.eliminated_at = eliminated_at
        ins.save(:validate => false)
      end

      # Check if ODK
      if ins.source == 'ODK Form'
        require 'open-uri'
        unless row_content[:br_site_pic].blank?
          ins.update_attribute(:before_photo, open(row_content[:br_site_pic])) rescue false
        end
        unless row_content[:br_site_elim_pic].blank?
          ins.update_attribute(:before_photo, open(row_content[:br_site_elim_pic])) rescue false
        end
      end

      # Get previous similar inspection
      ins.get_previous_similar_inspection

      # Assign submit points to all reporters
      if is.present? && ins.reporters.length > 0
        ins.reporters.each do |reporter|
          reporter.award_points_for_submitting
        end
      end
    end

    @csv.parsed_at = Time.zone.now
    @csv.save
  end
end
