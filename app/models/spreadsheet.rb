
# -*- encoding : utf-8 -*-
require "roo"

class Spreadsheet < ActiveRecord::Base
  attr_accessible :user_id
  self.table_name = "csvs"

  attr_accessible :csv
  has_attached_file :csv
  do_not_validate_attachment_file_type :csv

  belongs_to :user
  belongs_to :location

  has_many :reports, :dependent => :destroy, :foreign_key => :csv_id
  has_many :visits, :foreign_key => :csv_id
  has_many :csv_errors, :dependent => :destroy, :foreign_key => :csv_id
  has_many :inspections, :foreign_key => :csv_id

  def neighborhood
    return self.location.neighborhood
  end

  # The header of the data must include "fecha de visita" text so we iterate
  # over the rows until we find it.
  def self.calculate_row_index_of_header(spreadsheet)
    index = 3
    while spreadsheet.row(index)[0].to_s.downcase.exclude?("fecha de visita")
      index += 1
    end

    return index
  end

  def self.extract_header_from_spreadsheet(spreadsheet)
    start_index = Spreadsheet.calculate_row_index_of_header(spreadsheet)
    header      = spreadsheet.row(start_index)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }

    return header
  end

  def self.permitted_params
    [:user_id]
  end

  #----------------------------------------------------------------------------

  def self.extract_address_from_filepath(path)
    name = path.split("/")[-1]
    return name.gsub("xlsx", "").gsub(".", "").strip
  end

  #----------------------------------------------------------------------------

  def self.extract_rows_from_spreadsheet(spreadsheet)
    start_index = Spreadsheet.calculate_row_index_of_header(spreadsheet)
    header      = Spreadsheet.extract_header_from_spreadsheet(spreadsheet)

    rows = []
    (start_index + 1..spreadsheet.last_row).each do |i|
      row            = Hash[[header, spreadsheet.row(i)].transpose]
      rows << row
    end

    return rows
  end

  #----------------------------------------------------------------------------

  # Extract the attributes. NOTE: We use fuzzy matching instead of
  # exact matching since users may vary the columns slightly.
  def self.extract_content_from_row(row)
    visited_at         = row.select {|k,v| k.include?("fecha de visita")}.values[0].to_s
    room               = row["localización"].to_s
    breeding_site     = row.select {|k,v| k.include?("tipo")}.values[0].to_s
    is_protected       = row['protegido'].to_i
    is_pupae           = row["pupas"].to_i
    is_larvae          = row["larvas"].to_i
    is_chemical        = row["abatizado"].to_i
    eliminated_at      = row.select {|k,v| k.include?("fecha de elimina")}.values[0].to_s
    comments           = row.select {|k,v| k.include?("comentarios")}.values[0].to_s

    disease_report     = row.select {|k,v| k.include?("reporte")}.values[0].to_s
    disease_report     = nil if disease_report.blank?
    return {
      :visited_at    => visited_at,
      :health_report => disease_report,
      :room          => room,
      :breeding_site => breeding_site,
      :protected     => is_protected,
      :pupae         => is_pupae,
      :larvae        => is_larvae,
      :chemical      => is_chemical,
      :eliminated_at => eliminated_at,
      :comments      => comments
    }
  end

  def self.extract_breeding_site_from_row(row_content)
    type = row_content[:breeding_site].strip.downcase

    if type.include?("a")
      breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
    elsif type.include?("b")
      breeding_site = BreedingSite.find_by_code("B")
    elsif type.include?("l")
      breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
    elsif type.include?("m")
      breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
    elsif type.include?("p")
      breeding_site = BreedingSite.find_by_code("P")
    elsif type.include?("t")
      breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
    end

    return breeding_site
  end

  #----------------------------------------------------------------------------

  def self.generate_description_from_row_content(row_content)
    room = row_content[:room]
    prot     = (row_content[:protected] == 1) ? "si" : "no"
    chemical = (row_content[:chemical] == 1) ? "si" : "no"
    larvae   = (row_content[:larvae] == 1) ? "si" : "no"
    pupae    = (row_content[:pupae] == 1) ? "si" : "no"
    comments = row_content[:comments]

    description = ""
    description += "Localización: #{room}, " if room.present?
    description += "Protegido: #{prot}, Abatizado: #{chemical}, Larvas: #{larvae}, Pupas: #{pupae}"
    description += ", Comentarios sobre tipo y/o eliminación: #{comments}" if comments.present?

    return description
  end

  #----------------------------------------------------------------------------

  def self.generate_uuid_from_row_index_and_address(row, row_index, address)
    row_content = Spreadsheet.extract_content_from_row(row)

    # 4d. Generate a UUID to identify the row that the report will correspond
    # to. We define the UUID based on
    # * House location,
    # * Date of visit,
    # * The room within the house,
    # * Type of site,
    # * Properties identified at the site.
    # If there is a match, then we simply update the existing report.
    visited_at = row_content[:visited_at]
    room       = row_content[:room]
    type       = row_content[:breeding_site].strip.downcase
    prot       = row_content[:protected].to_s
    chemical   = row_content[:chemical].to_s
    larvae     = row_content[:larvae].to_s
    pupae      = row_content[:pupae].to_s

    uuid = (row_index.to_s + address + visited_at + room + type + prot + pupae + larvae + chemical)
    uuid = uuid.strip.downcase.underscore
    return uuid
  end

  #----------------------------------------------------------------------------

  def check_for_breeding_site_errors(rows)
    rows.each do |row|
      row_content = Spreadsheet.extract_content_from_row(row)
      next if row_content[:breeding_site].blank?

      type = row_content[:breeding_site].strip.downcase
      if Spreadsheet.accepted_breeding_site_codes.exclude?(type[0])
        CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::UNKNOWN_CODE)
      end
    end
  end

  def check_for_date_errors(rows)
    parsed_current_visited_at = nil

    rows.each do |row|
      row_content = Spreadsheet.extract_content_from_row(row)

      # Check for any errors related to visited_at.
      if row_content[:visited_at].present?
        begin
          parsed_current_visited_at = Time.zone.parse( row_content[:visited_at] )
        rescue
          CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::UNPARSEABLE_DATE)
          next
        end

        if parsed_current_visited_at.future?
          CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::VISIT_DATE_IN_FUTURE)
          next
        end
      end

      # Check for any errors related to eliminated_at.
      if row_content[:eliminated_at].present?
        begin
          eliminated_at = Time.zone.parse( row_content[:eliminated_at] )
        rescue
          CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::UNPARSEABLE_DATE)
          next
        end

        # If the date of elimination is in the future or before visit date, then let's raise an error.
        if eliminated_at.present?
          if eliminated_at.future?
            CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::ELIMINATION_DATE_IN_FUTURE)
            next
          end

          if parsed_current_visited_at && eliminated_at < parsed_current_visited_at
            CsvError.create(:csv_id => self.id, :error_type => CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE)
            next
          end
        end
      end
    end
  end

  #----------------------------------------------------------------------------

  def self.load_spreadsheet(file)
    # TODO: This should technically be abstracted into paperclip_defaults.
    # See https://github.com/thoughtbot/paperclip#uri-obfuscation
    # See http://stackoverflow.com/questions/22416990/paperclip-unable-to-change-default-path
    file_location = (Rails.env.production? || Rails.env.staging?) ? file.url : file.path

    if File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file_location, :file_warning => :ignore)
    end

    return spreadsheet
  end

  def self.clean_breeding_site_codes
    return ["n"]
  end

  def self.accepted_breeding_site_codes
    return ["a", "b", "l", "m", "p", "t", "x"] + self.clean_breeding_site_codes
  end

end
