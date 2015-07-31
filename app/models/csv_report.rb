# -*- encoding : utf-8 -*-
require "roo"

class CsvReport < ActiveRecord::Base
  attr_accessible :csv
  has_attached_file :csv
  do_not_validate_attachment_file_type :csv

  belongs_to :user
  belongs_to :location
  belongs_to :neighborhood

  has_many :reports, :dependent => :destroy
  has_many :visits, :through => :reports
  has_many :csv_errors, :dependent => :destroy

  validates :neighborhood_id, :presence => true

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
    start_index = CsvReport.calculate_row_index_of_header(spreadsheet)
    header      = spreadsheet.row(start_index)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }

    return header
  end

  #----------------------------------------------------------------------------

  def self.extract_address_from_spreadsheet(spreadsheet)
    address = spreadsheet.row(1)[1]
    address = address.to_s if address.present?
    return address
  end

  #----------------------------------------------------------------------------

  def self.extract_rows_from_spreadsheet(spreadsheet)
    start_index = CsvReport.calculate_row_index_of_header(spreadsheet)
    header      = CsvReport.extract_header_from_spreadsheet(spreadsheet)

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
    row_content = CsvReport.extract_content_from_row(row)

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

  def self.load_spreadsheet(file)
    # TODO: This should technically be abstracted into paperclip_defaults.
    # See https://github.com/thoughtbot/paperclip#uri-obfuscation
    # See http://stackoverflow.com/questions/22416990/paperclip-unable-to-change-default-path
    file_location = (Rails.env.production? ? file.url : file.path)

    if File.extname( file.original_filename ) == ".csv"
      spreadsheet = Roo::CSV.new(file_location, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xls"
      spreadsheet = Roo::Excel.new(file_location, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file_location, :file_warning => :ignore)
    end

    return spreadsheet
  end

  def self.accepted_breeding_site_codes
    return ["a", "b", "l", "m", "p", "t", "x", "n"]
  end

end
