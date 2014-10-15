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

  # Assume the template is as follows:
  # ["Visita", "Fecha", "Hora", "Tipo", "Protegido", "Abatizado", "Larvas", "Pupas"]
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

    header = spreadsheet.row(1)
    header.map! {|h| h.downcase.strip}

    before_reports = []
    after_reports  = []
    current_visit = -1
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]

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
      else
        flash[:alert] = "One or more of the breeding sites can't be identified. Please use B, T, N or O to identify breeding sites."
        render "new" and return
      end

    end

    if current_visit == -1
      flash[:alert] = "You need to have at least 1 visit to a location. Please redo the CSV report."
      render "new" and return
    end

    # At this point, we have at least one, but no more than two visits to the location.
    # The before_* and after_* reports are also prefilled.


  end


end
