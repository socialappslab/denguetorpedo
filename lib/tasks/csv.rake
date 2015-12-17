# encoding: UTF-8
require "roo"

#------
# NOTE: This is a one-time rake task that will place all
# existing users into Mare neighborhood.

namespace :csvs do
  # This task iterates over all files in /tmp/csvs (which should be THE files
  # that Harold's team is using for the entomological survey), identifies the
  # address, attempts to locate CsvReport associated with this address, and creates
  # a new CSV instance with the matched CsvReport.
  task :copy_csv_reports => [:environment] do
    addys = []

    nonunique_addresses = []
    nonunique_csvs      = []
    Dir[Rails.root + "lib/quinta_csvs/*.xlsx"].each_with_index do |filepath, index|
      puts "\n\n\nLooking at index = #{index} \n\n\n"
      address   = Csv.extract_address_from_filepath(filepath)
      locations = Location.where(:address => address)

      # If the address is not unique to a location, then let's keep track of it and add
      # it to manual processing.
      if locations.count > 1
        nonunique_addresses << address
        puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
        next
      end

      # If there is not matching location, then let's create it and the CSV.
      if locations.count == 0
        location                 = Location.new(:address => address)
        location.neighborhood_id = 8 # TODO: This should change with the directory.
        location.save(:validate => false)

        csv             = Csv.new
        csv.csv         = File.open(filepath)
        csv.user_id     = 253 # This is Harold.
        csv.location_id = location.id
        csv.save(:validate => false)

        puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
        next
      end

      # At this point, we have a unique location. If the Csv instance already exists
      # (by running this rake task previously), then let's skip it.
      location = locations.first
      csv = Csv.find_by_location_id(location.id)
      if csv.present?
        puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
        next
      end

      # A Csv instance DOES NOT exist. Let's build it here.
      csv             = Csv.new
      csv.csv         = File.open(filepath)
      csv.location_id = location.id
      csv.user_id     = 253 # TODO: This should change to whoever Harold wants.
      csv.save(:validate => false)

      # If the location is not unique to a CSV, then let's add it and process it
      # manually later.
      csv_reports = CsvReport.where(:location_id => location.id)
      if csv_reports.count > 1
        nonunique_csvs << location.id
        puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
        next
      end

      # Continue as no additional changes need to be made.
      if csv_reports.count == 0
        puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
        next
      end

      # At this point, we have a unique CsvReport. Let's copy the attributes
      # and update the associated models.
      csv_report    = csv_reports.first
      csv.user_id   = csv_report.user_id
      csv.save(:validate => false)

      CsvError.where(:csv_report_id => csv_report.id).find_each do |csve|
        csve.update_column(:csv_id, csv.id)
      end

      Report.where(:csv_report_id => csv_report.id).find_each do |r|
        r.update_column(:csv_id, csv.id)
      end

      puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
    end

    puts "-" * 50
    puts "There are #{nonunique_addresses.count} non-unique addresses for locations. They are: "
    puts "nonunique_addresses: #{nonunique_addresses.inspect}"
    puts "There are #{nonunique_csvs.count} non-unique locations for csvs. They are: "
    puts "nonunique_csvs: #{nonunique_csvs.inspect}"
    puts "-" * 50
  end
end