#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/new

  def new
    @csv_report = CsvReport.new
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/1/csv_reports


  def create
    @csv_report = CsvReport.new

    # Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      flash[:alert] = "You need to mark the location on the map!"
      render "new" and return
    end

    file = params[:csv_report][:csv]

    if File.extname( file.original_filename ) == ".csv"
      spreadsheet = Roo::CSV.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xls"
      spreadsheet = Roo::Excel.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file.tempfile.path, :file_warning => :ignore)
    else
      flash[:alert] = "You must upload a .csv, .xls or a .xlsx file"
      render "new" and return
    end

    # Assume the template is as follows:
    # * First row is the house number or an address of sorts
    # * Second row is empty
    # * Third row is the beginning of the table,
    # * All subsequent rows are entries in the table.
    #
    header  = spreadsheet.row(1)
    puts "header: #{header}"
    address = "#{header[1]}"

    start_index = 2
    while spreadsheet.row(start_index)[0].blank?
      start_index += 1
    end

    # Define the header.
    header  = spreadsheet.row(start_index)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }

    before_reports = []
    after_reports  = []
    current_visit = -1
    parsed_content = []
    # The rows of the table are:
    # {
    #   "fecha de visita (aaaammdd)"=>20141010.0, "tipo de criadero"=>"B",
    #   "localización"=>"Cerca del baño", "¿protegido"=>0.0, "¿abatizado"=>0.0,
    #   "¿larvas"=>1.0, "pupas"=>0.0, "¿foto de criadero"=>nil,
    #   "eliminado (aaaammdd)"=>20141012.0, "¿foto de eliminación"=>nil,
    #   "comentarios sobre tipo y/o eliminación*"=>nil
    # }
    (start_index + 1..spreadsheet.last_row).each do |i|
      row            = Hash[[header, spreadsheet.row(i)].transpose]
      date           = row["fecha de visita (aaaammdd)"]
      site           = row["tipo de criadero"]
      location_within_house = row["localización"]
      comments       = row.select {|k,v| k.include?("comentarios")}.values[0]
      is_protected   = row['protegido'].to_i
      is_pupas       = row["pupas"].to_i
      is_larvas      = row["larvas"].to_i
      is_covered     = row["abatizado"].to_i


      parsed_content << row

      # Update the current visit to differentiate between before and after report.
      current_visit = 1 if date.present?

      # This is the csv_uuid on the reports table. We use this column
      # to identify the row that corresponds to this report.
      uuid = date.to_s + site.to_s + location_within_house.to_s + comments.to_s + is_protected.to_s + is_pupas.to_s + is_larvas.to_s + is_covered.to_s
      puts "uuid: #{uuid}"
      next if Report.where(:csv_uuid => uuid).present?


      # Ensure that the breeding site is identifiable.
      if site && ["a", "b", "l", "m", "p", "t", "o"].include?( site.strip.downcase )
        type = site.strip.downcase

        if type == "a"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
        elsif type == "b"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
        elsif type == "l"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
        elsif type == "m"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
        elsif type == "p"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
        elsif type == "t"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
        end

      else
        next
        # flash[:alert] = "One or more of the breeding sites can't be identified. Please use A, B, L, M, P, T, or O to identify breeding sites."
        # render "new" and return
      end

      # At this point, we know the breeding site.
      description = ""
      description += "Localización: #{location_within_house}, " if location_within_house.present?
      description += "Comentarios sobre tipo y/o eliminación: #{comments}, " if comments.present?
      description += "Protegido: #{is_protected}, Abatizado: #{is_covered}, Larvas: #{is_larvas}, Pupas: #{is_pupas}"
      before_reports << {:breeding_site => breeding_site, :description => description, :csv_uuid => uuid}
    end

    if current_visit == -1
      flash[:alert] = "You need to have at least 1 visit to a location. Please redo the CSV report."
      render "new" and return
    end

    puts "before_reports: #{before_reports}"


    # At this point, we have at least one, but no more than two visits to the location.
    # The before_* and after_* reports are also prefilled. Let's create the CsvReport
    # and the reports.
    @csv_report.csv = file
    @csv_report.parsed_content = parsed_content.to_json
    @csv_report.save!

    # Now let's create the location.
    location = Location.create!(:latitude => lat, :longitude => long, :address => address)

    before_reports.each do |report|
      r = Report.new
      r.report           = report[:description]
      r.breeding_site_id = report[:breeding_site].id if report[:breeding_site].present?
      r.location_id      = location.id
      r.neighborhood_id  = @neighborhood.id
      r.reporter_id      = @current_user.id
      r.csv_report_id    = @csv_report.id
      r.csv_uuid         = report[:csv_uuid]
      r.save(:validate => false)
    end

    flash[:notice] = "The reports were successfully created from CSV."
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end


end
