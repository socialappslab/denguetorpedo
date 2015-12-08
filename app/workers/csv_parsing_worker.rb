require "sidekiq"

class CsvParsingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :csv_parsing, :retry => true, :backtrace => true

  def perform(csv_id)
    # Make sure that we're parsing relative to the correct timezone.
    Time.zone = "America/Guatemala"

    @csv_report   = CsvReport.find_by_id(csv_id)
    return if @csv_report.blank?

    # Reset any verification we may have done.
    @csv_report.verified_at = nil

    @neighborhood = @csv_report.neighborhood
    location      = @csv_report.location

    # Identify the file content type.
    spreadsheet = CsvReport.load_spreadsheet( @csv_report.csv )
    unless spreadsheet
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::UNKNOWN_FORMAT)
      return
    end

    # Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = CsvReport.extract_address_from_spreadsheet(spreadsheet)
    if address.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_HOUSE)
      return
    end

    # Error out if there are no reports extracted.
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    if rows.blank?
      CsvError.create(:csv_report_id => @csv_report.id, :error_type => CsvError::Types::MISSING_VISITS)
      return
    end

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    header = CsvReport.extract_header_from_spreadsheet(spreadsheet)

    #--------------------------------------------------------------------------
    # At this point, we know that there is at least one row. Let's see if there
    # are any incorrect breeding site codes.
    @csv_report.check_for_breeding_site_errors(rows)

    # Iterate over the rows, checking if any dates are invalid.
    @csv_report.check_for_date_errors(rows)

    # If there are any errors, we can't proceed so let's offload right now and let
    # the user re-upload when they've fixed the errors.
    return if @csv_report.csv_errors.present?

    # Let's parse the content and assign it to the database column.
    @csv_report.parsed_content = rows.to_json

    #--------------------------------------------------------------------------
    # Let's iterate over the rows and create/update reports.
    #------

    # At this point, we do not have any errors. Let's iterate over each row, and
    # create/update the reports accordingly.
    current_visited_at = nil
    rows.each_with_index do |row, row_index|
      row_content = CsvReport.extract_content_from_row(row)

      # Let's begin by creating a visit, if applicable. We create a visit
      # anytime there is an entry in visited_at column and that entry doesn't match
      # the last parsed entry.
      if row_content[:visited_at].present? && current_visited_at != row_content[:visited_at]
        current_visited_at = Time.zone.parse( row_content[:visited_at] )
        v = Visit.find_or_create_visit_for_location_id_and_date(location.id, current_visited_at)
        v.update_column(:health_report, row_content[:health_report])
      end

      # Why do this? The specific bug here was that a valid visit date was completely ignored
      # because the row didn't have a breeding site. The correct solution is to
      # parse and store the visit date, and then make a decision on whether to
      # continue parsing the remaining columns.
      next if row_content[:breeding_site].blank?

      # If the breeding code is N or X then we will NOT create a report. Otherwise,
      # we will, *and* we may also add a unique identifier to the report.
      raw_breeding_code = row_content[:breeding_site].strip.downcase
      next if CsvReport.clean_breeding_site_codes.include?(raw_breeding_code)

      # At this point, we have a valid breeding code. Let's parse and start creating
      # the report.
      uuid          = CsvReport.generate_uuid_from_row_index_and_address(row, row_index, address)
      description   = CsvReport.generate_description_from_row_content(row_content)
      breeding_site = CsvReport.extract_breeding_site_from_row(row_content)

      # We say that the report has a field identifier if the breeding site CSV column
      # also has an integer associated with it.
      field_id = nil
      field_id = raw_breeding_code if raw_breeding_code =~ /\d/

      # Add to reports only if the code doesn't equal "negative" code.
      eliminated_at = Time.zone.parse( row_content[:eliminated_at] ) if row_content[:eliminated_at].present?

      # If this is an existing report, then let's update a subset of properties
      # on this report.
      r = @csv_report.reports.find_by_field_identifier(field_id) if field_id.present?
      if r.present?
        r.report             = description
        r.breeding_site_id   = breeding_site.id if breeding_site.present?
        r.protected          = row_content[:protected]
        r.chemically_treated = row_content[:chemical]
        r.larvae             = row_content[:larvae]
        r.pupae              = row_content[:pupae]
        r.csv_uuid           = uuid
        r.save(:validate => false)

        # Create an inspection regardless if eliminated_at is present or not. This
        # ensures that we have a 1-1 correspondence between a row and an inspection.
        v = r.find_or_create_visit_for_date(current_visited_at)
        position = r.inspections.where(:visit_id => v).count
        Inspection.create(:visit_id => v.id, :report_id => r.id, :identification_type => r.original_status, :position => position)
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
        r = @csv_report.reports.find_by_csv_uuid(uuid)
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
          r.reporter_id        = @csv_report.user_id
          r.csv_report_id      = @csv_report.id
          r.csv_uuid           = uuid
          r.eliminated_at      = eliminated_at
          r.save(:validate => false)

          v = r.find_or_create_visit_for_date(r.created_at)
          position = r.inspections.where(:visit_id => v).count
          Inspection.create(:visit_id => v.id, :report_id => r.id, :identification_type => r.original_status)
        end
      end

      # We create a special "followup" visit for reports with a field identifier.
      # All other reports are assumed to be new.
      if eliminated_at.present?
        r.eliminated_at = eliminated_at
        r.save(:validate => false)

        # Create an inspection whose position is dependent on the existing inspections
        # associated with this report.
        v = r.find_or_create_visit_for_date(r.eliminated_at)
        position = r.inspections.where(:visit_id => v).count
        Inspection.create(:visit_id => v.id, :report_id => r.id, :identification_type => Inspection::Types::NEGATIVE, :position => position)
      end
    end

    @csv_report.parsed_at      = Time.zone.now
    @csv_report.save
  end
end
