# encoding: UTF-8
require "roo"

#------
# Parse the raw CSV data given to me by Harold, and extract CSVs corresponding
# to a week in August ()
task :parse_nicaragua_data => :environment do
  csvs = []
  Dir["/Users/dmitri/Desktop/csvs/*.xlsx"].each do |file|
    csvr = CsvReport.new
    csvr.csv = File.open(file)
    csvr.save(:validate => false)

    spreadsheet = CsvReport.load_spreadsheet( csvr.csv )
    rows = CsvReport.extract_rows_from_spreadsheet(spreadsheet)
    rows.each_with_index do |row, row_index|
      row_content = CsvReport.extract_content_from_row(row)
      if row_content[:visited_at].present?
        time = Time.zone.parse( row_content[:visited_at] )

        if time.month == 8 && time.day >= 3 && time.day <= 9
          csvs << csvr.csv.original_filename
        end
      end
    end

    csvr.destroy
  end

  csvs.uniq!
  puts "csvs: #{csvs} | count = #{csvs.count}"

  # Output: ["N002001009...xlsx", "N002002037...xlsx", "N002003070...xlsx", "N002004104...xlsx", "N002005110...xlsx", "N002005121...xlsx", "N002006134...xlsx", "N002006137...xlsx"]
end
