require "sidekiq"

class SpreadsheetParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform(csv_id)
    # Make sure that we're parsing relative to the correct timezone.
    Time.zone = "America/Guatemala"

    @csv   = Spreadsheet.find_by_id(csv_id)
    return if @csv.blank?

    # Reset any verification we may have done.
    @csv.verified_at = nil

    location      = @csv.location
    @neighborhood = location.neighborhood
    address       = location.address

    # Identify the file content type.
    spreadsheet = Spreadsheet.load_spreadsheet( @csv.csv )
    unless spreadsheet
      CsvError.create(:csv_id => @csv.id, :error_type => CsvError::Types::UNKNOWN_FORMAT)
      return
    end

    # Error out if there are no reports extracted.
    rows = Spreadsheet.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      CsvError.create(:csv_id => @csv.id, :error_type => CsvError::Types::MISSING_VISITS)
      return
    end

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = Spreadsheet.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    @csv.check_for_breeding_site_errors(rows)

    # Iterate over the rows, checking if any dates are invalid.
    @csv.check_for_date_errors(rows)

    # If there are any errors, we can't proceed so let's offload right now and let
    # the user re-upload when they've fixed the errors.
    return if @csv.csv_errors.present?

    #--------------------------------------------------------------------------
    # Let's iterate over the rows and create/update reports.
    #------

    # At this point, we do not have any errors. Let's iterate over each row, and
    # create/update the reports accordingly.
    current_visited_at = nil
    rows.each_with_index do |row, row_index|
      row_content = Spreadsheet.extract_content_from_row(row)

      # Let's begin by creating a visit, if applicable. We create a visit
      # anytime there is an entry in visited_at column and that entry doesn't match
      # the last parsed entry.
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at = Time.zone.parse( row_content[:visited_at] )
        v = Visit.find_or_create_visit_for_location_id_and_date(location.id, current_visited_at)
        v.update_column(:health_report, row_content[:health_report])
        v.update_column(:csv_id, @csv.id)
      end

      # Why do this? The specific bug here was that a valid visit date was completely ignored
      # because the row didn't have a breeding site. The correct solution is to
      # parse and store the visit date, and then make a decision on whether to
      # continue parsing the remaining columns.
      next if row_content[:breeding_site].blank?

      # If the breeding code is N or X then we will NOT create a report. Otherwise,
      # we will, *and* we may also add a unique identifier to the report.
      raw_breeding_code = row_content[:breeding_site].strip.downcase
      next if Spreadsheet.clean_breeding_site_codes.include?(raw_breeding_code)

      # At this point, we have a valid breeding code. Let's parse and start creating
      # the report.
      uuid          = Spreadsheet.generate_uuid_from_row_index_and_address(row, row_index, address)
      description   = Spreadsheet.generate_description_from_row_content(row_content)
      breeding_site = Spreadsheet.extract_breeding_site_from_row(row_content)

      # We say that the report has a field identifier if the breeding site CSV column
      # also has an integer associated with it.
      field_id = nil
      field_id = raw_breeding_code if raw_breeding_code =~ /\d/

      # Add to reports only if the code doesn't equal "negative" code.
      eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

      # If this is an existing report, then let's update a subset of properties
      # on this report.
      r = @csv.reports.find_by_field_identifier(field_id) if field_id.present?
      if r.present?
        r.report             = description
        r.breeding_site_id   = breeding_site.id if breeding_site.present?
        r.protected          = row_content[:protected]
        r.chemically_treated = row_content[:chemical]
        r.larvae             = row_content[:larvae]
        r.pupae              = row_content[:pupae]
        r.csv_uuid           = uuid
        r.csv_id             = @csv.id
        r.save(:validate => false)
      else
        # At this point, this isn't a report with a field identifier. Because
        # we're parsing the whole CSV, there are two options:
        # 1. This report has been previously created from a previous upload.
        #    In this case, we should be able to identify it through the UUID. The
        #    only attributes we should update is whether it has been eliminated,
        #    which we do further down.
        # 2. The other possibility is that this is a new report. In this case, we
        #    create it with all attributes, and leave the checking of eliminated_at
        #    further down.
        r = @csv.reports.find_by_csv_uuid(uuid)
        if r.blank?
          r            = Report.new
          r.field_identifier   = field_id
          r.created_at         = current_visited_at
          r.report             = description
          r.breeding_site_id   = breeding_site.id if breeding_site.present?
          r.protected          = row_content[:protected]
          r.chemically_treated = row_content[:chemical]
          r.larvae             = row_content[:larvae]
          r.pupae              = row_content[:pupae]
          r.location_id        = location.id
          r.neighborhood_id    = @neighborhood.id
          r.reporter_id        = @csv.user_id
          r.csv_id             = @csv.id
          r.csv_uuid           = uuid
          r.eliminated_at      = eliminated_at
          r.save(:validate => false)
        end
      end

      # Create an inspection regardless if eliminated_at is present or not. This
      # ensures that we have a 1-1 correspondence between a row and an inspection.
      find_or_create_visit_and_inspection(@csv, current_visited_at, r)

      # We create a special "followup" visit for reports with a field identifier.
      # All other reports are assumed to be new.
      if eliminated_at.present?
        r.eliminated_at = eliminated_at
        r.save(:validate => false)

        # Create an inspection whose position is dependent on the existing inspections
        # associated with this report.
        find_or_create_visit_and_elimination_inspection(@csv, eliminated_at, r)
      end
    end

    @csv.parsed_at = Time.zone.now
    @csv.save
  end

  def find_or_create_visit_and_inspection(csv, date, report)
    v = Visit.find_or_create_visit_for_location_id_and_date(csv.location_id, date)
    v.update_column(:csv_id, csv.id)

    ins = Inspection.find_by_visit_id_and_report_id(v.id, report.id)
    ins = Inspection.new(:visit_id => v.id, :report_id => report.id) if ins.blank?
    ins.csv_id              = csv.id
    ins.identification_type = report.original_status
    ins.position            = csv.inspections.count
    ins.save
  end

  def find_or_create_visit_and_elimination_inspection(csv, date, report)
    v = Visit.find_or_create_visit_for_location_id_and_date(csv.location_id, date)
    v.update_column(:csv_id, csv.id)

    ins = Inspection.find_by_visit_id_and_report_id_and_identification_type(v.id, report.id, Inspection::Types::NEGATIVE)
    ins = Inspection.new(:visit_id => v.id, :report_id => report.id) if ins.blank?
    ins.csv_id              = csv.id
    ins.identification_type = Inspection::Types::NEGATIVE
    ins.position            = csv.inspections.count
    ins.save
  end
end
