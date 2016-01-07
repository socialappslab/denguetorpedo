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
    galope = Neighborhood.find_by_name("Galope")
    copy_files_for_neighborhood(Rails.root + "lib/nicaragua_csvs_july_december_2015/galope/*.xlsx", galope)

    la_quinta = Neighborhood.find_by_name("La Quinta")
    copy_files_for_neighborhood(Rails.root + "lib/nicaragua_csvs_july_december_2015/la_quinta/*.xlsx", la_quinta)

    tangara = Neighborhood.find_by_name("Tangará")
    copy_files_for_neighborhood(Rails.root + "lib/nicaragua_csvs_july_december_2015/tangara/*.xlsx", tangara)
  end
end

def copy_files_for_neighborhood(path, neighborhood)
  nonunique_addresses = []

  Dir[path].each_with_index do |filepath, index|
    puts "\n\n\nLooking at index = #{index} \n\n\n"
    address   = Spreadsheet.extract_address_from_filepath(filepath)
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
      location.neighborhood_id = neighborhood.id
      location.save(:validate => false)
    else
      location = locations.first
    end

    # At this point, we have a unique location. If the Spreadsheet instance already exists
    # (by running this rake task previously), then let's skip it.

    csv = Spreadsheet.find_by_location_id(location.id)
    if csv.present?
      puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
      next
    end

    # A Spreadsheet instance DOES NOT exist. Let's build it here.
    csv             = Spreadsheet.new
    csv.csv         = File.open(filepath)
    csv.location_id = location.id
    csv.user_id     = 253 # TODO: This should change to whoever Harold wants.
    csv.save(:validate => false)

    # Attempt to copy over existing association to the new Spreadsheet instance.
    # If there is no data to copy, then move on.
    csv_reports = CsvReport.where(:location_id => location.id)
    if csv_reports.count > 1
      # If we don't have a unique csv report to copy (because we previously allowed
      # to distribute visits across multiple CSVs), then let's assign the first
      # CsvReport user to user_id, and then associate all reports that have that location
      # and csv_report_id with the new csv_id.
      csv.user_id = csv_reports.first.user_id
      csv.save(:validate => false)

      reports = Report.where(:location_id => location.id).where(:csv_report_id => csv_reports.pluck(:id))
      reports.find_each {|r| r.update_column(:csv_id, csv.id) }
    elsif csv_reports.count == 1
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
    end

    puts "\n\n\nDone with address = #{address} (index = #{index})\n\n\n"
  end

  puts "-" * 50
  puts "There are #{nonunique_addresses.count} non-unique addresses for locations. They are: "
  puts "nonunique_addresses: #{nonunique_addresses.inspect}"
  puts "-" * 50
  puts "\n" * 10


end
