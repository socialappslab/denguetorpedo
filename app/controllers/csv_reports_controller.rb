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
    # ["Visita", "Fecha", "Hora", "Tipo", "Total de tipo", "Protegido?", "Abatizado?", "Larvas?", "Pupas?"]
    header  = spreadsheet.row(1)
    address = "#{header[1]}"
    header  = spreadsheet.row(3)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "") }

    before_reports = []
    after_reports  = []
    current_visit = -1
    parsed_content = []
    (4..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      puts "row; #{row}"
      parsed_content << row

      # Ensure that there are at most two visits to a location.
      if row["visita"].to_i > 2
        flash[:alert] = "There can only be at most 2 visits to a location. Please redo the CSV report."
        render "new" and return
      end

      # Update the current visit to differentiate between before and after report.
      current_visit = row["visita"].to_i if row["visita"].to_i != 0

      # Ensure that the breeding site is identifiable.
      if row["tipo"] && ["b", "t", "n", "o"].include?( row["tipo"].strip.downcase )
        type = row["tipo"].strip.downcase



        if type == "b"
          site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
        elsif type == "t"
          site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
        elsif type == "n"
          site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
        else
          site = BreedingSite.find_by_string_id(BreedingSite::Types::OTHER)
        end

      else
        flash[:alert] = "One or more of the breeding sites can't be identified. Please use B, T, N or O to identify breeding sites."
        render "new" and return
      end

      # At this point, we know the breeding site.
      description = "Total de tipo: #{row['total de tipo']}, Protegido: #{row['protegido']}, Abatizado: #{row['abatizado']}, Larvas: #{row['larvas']}, Pupas: #{row['pupas']}"
      before_reports << {:breeding_site => site, :description => description}
    end

    if current_visit == -1
      flash[:alert] = "You need to have at least 1 visit to a location. Please redo the CSV report."
      render "new" and return
    end


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
      r.breeding_site_id = report[:breeding_site].id
      r.location_id      = location.id
      r.neighborhood_id  = @neighborhood.id
      r.reporter_id      = @current_user.id
      r.save(:validate => false)
    end

    flash[:notice] = "The reports were successfully created from CSV."
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end


end
