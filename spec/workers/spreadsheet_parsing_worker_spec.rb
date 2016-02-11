# -*- encoding : utf-8 -*-
require "rails_helper"

describe SpreadsheetParsingWorker do
  let(:user) 		       { FactoryGirl.create(:user) }
  let(:csv_file)       { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:real_csv_file)  { File.open("spec/support/pruebaAutoreporte4.xlsx") }
  let(:location)       { create(:location, :address => "N123456") }
  let(:csv)            { FactoryGirl.create(:spreadsheet, :csv => csv_file, :user_id => user.id, :location => location) }
  let(:real_csv)       { FactoryGirl.create(:spreadsheet, :csv => real_csv_file, :user_id => user.id, :location => location) }

  before(:each) do
    Sidekiq::Testing.inline!
  end

  it "sets parsed_at" do
    SpreadsheetParsingWorker.perform_async(csv.id)
    expect(Spreadsheet.last.parsed_at).not_to eq(nil)
  end

  it "creates a date with CST timezone" do
    csv = FactoryGirl.create(:spreadsheet, :csv => File.open(Rails.root + "spec/support/updating_csv/initial_visit/N0020010034234243.xlsx"), :location => location)
    SpreadsheetParsingWorker.perform_async(csv.id)
    report = csv.reload.reports.first
    expect(report.created_at.strftime("%Z")).to eq("CST")
  end

  it "creates a new CSV file" do
    expect {
      SpreadsheetParsingWorker.perform_async(csv.id)
    }.to change(Spreadsheet, :count).by(1)
  end

  it "associates the CSV with the user" do
    SpreadsheetParsingWorker.perform_async(csv.id)
    expect(Spreadsheet.last.user_id).to eq(user.id)
  end

  it "creates 3 new reports" do
    expect {
      SpreadsheetParsingWorker.perform_async(csv.id)
    }.to change(Report, :count).by(3)
  end

  it "current visit date of specific row is properly parsed" do
    # The specific bug here was that a valid visit date was completely ignored
    # because the row didn't have a breeding site. The correct solution is to
    # parse and store the visit date, and then make a decision on whether to
    # proceed or not to next row.
    csv = File.open("spec/support/csv/visit_date_row_bug.xlsx")
    csv = FactoryGirl.create(:spreadsheet, :csv => csv, :location => location)
    SpreadsheetParsingWorker.perform_async(csv.id)
    csv = Spreadsheet.last
    expect(csv.parsed_at).not_to eq(nil)
  end

  #----------------------------------------------------------------------------

  describe "with errors" do
    it "creates wrong format error" do
      csv = create(:spreadsheet, :location => location, :csv => File.open(Rails.root + "spec/support/foco_marcado.jpg"))
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNKNOWN_FORMAT)
    end

    it "returns unknown code error" do
      csv = File.open("spec/support/csv/unknown_code.xlsx")
      csv = create(:spreadsheet, :csv => csv, :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNKNOWN_CODE)
    end

    it "returns visit date in future error" do
      csv = File.open("spec/support/csv/inspection_date_in_future.xlsx")
      csv = create(:spreadsheet, :csv => csv, :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::VISIT_DATE_IN_FUTURE)
    end

    it "returns elimination date in future error" do
      csv = File.open("spec/support/csv/elimination_date_in_future.xlsx")
      csv = create(:spreadsheet, :csv => csv, :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::ELIMINATION_DATE_IN_FUTURE)
    end

    it "returns elimination date before visit date error" do
      csv = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
      csv = create(:spreadsheet, :csv => csv, :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE)
    end

    it "returns unparseable date error" do
      csv = File.open("spec/support/csv/unparseable_datetime.xlsx")
      csv = create(:spreadsheet, :csv => csv, :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNPARSEABLE_DATE)
    end
  end

  #----------------------------------------------------------------------------

  describe "the parsed Visit attributes" do
    before(:each) do
      SpreadsheetParsingWorker.perform_async(csv.id)
    end

    it "creates 4 visits" do
      expect(Visit.count).to eq(4)
    end

    it "correctly sets inspection type" do
      ls = Visit.where("DATE(visited_at) = ?", "2014-12-24").first
      expect(ls.reload.identification_type).to eq(Report::Status::POSITIVE)

      # NOTE: These should be positive since the above location status is positive,
      # and still hasn't been eliminated.
      ls = Visit.where("DATE(visited_at) = ?", "2014-12-31").first
      expect(ls.identification_type).to eq(Report::Status::POTENTIAL)

      # TODO: Perhaps we should instead think of Visit as Visits that
      # essentially categorize each visit as POSITIVE, POTENTIAL, or NEGATIVE.
      # The status of a location is then dependent on whether each visit resolved
      # its status... We would need to define what "resolved" means in this context.
      ls = Visit.where("DATE(visited_at) = ?", "2015-01-10").first
      expect(ls.identification_type).to eq(Report::Status::NEGATIVE)
    end

    it "correctly sets the health report" do
      ls = Visit.where("DATE(visited_at) = ?", "2014-12-24").first
      expect(ls.health_report).to eq("3c5d")

      ls = Visit.where("DATE(visited_at) = ?", "2014-12-31").first
      expect(ls.health_report).to eq("1c1d")

      ls = Visit.where("DATE(visited_at) = ?", "2015-01-10").first
      expect(ls.health_report).to eq("0c0d")
    end
  end

  describe "the parsed Report attributes" do
    before(:each) do
      SpreadsheetParsingWorker.perform_async(csv.id)
    end


    it "correctly sets inspection date" do
      r = Report.order("id").first
      expect(r.created_at.strftime("%Y-%m-%d")).to eq("2014-12-24")
    end

    it "correctly sets elimination date" do
      r = Report.order("id")[1]
      expect(r.eliminated_at.strftime("%Y-%m-%d")).to eq("2014-12-26")
    end

    it "doesn't set completion date" do
      Report.find_each do |r|
        expect(r.completed_at).to eq(nil)
      end
    end

    it "correctly sets status" do
      r = Report.order("id").first
      expect(r.status).to eq(Report::Status::POSITIVE)

      r = Report.order("id")[1]
      expect(r.status).to eq(Report::Status::POSITIVE)

      r = Report.order("id")[2]
      expect(r.status).to eq(Report::Status::POTENTIAL)
    end
  end

  context "when uploading the same CSV", :after_commit => true do
    before(:each) do
      SpreadsheetParsingWorker.perform_async(csv.id)
    end

    it "reuses the same location" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.not_to change(Location, :count)
    end

    it "does not create new Spreadsheet" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.not_to change(Spreadsheet, :count)
    end

    it "does NOT create new reports" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.not_to change(Report, :count)
    end

    it "does NOT create new Visit" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  context "when uploading the same but updated CSV", :after_commit => true do
    before(:each) do
      csv = FactoryGirl.create(:spreadsheet, :csv => File.open(Rails.root + "spec/support/updating_csv/initial_visit/N0020010034234243.xlsx"), :location => location)
      SpreadsheetParsingWorker.perform_async(csv.id)

      @subsequent_csv     = csv
      @subsequent_csv.csv = File.open(Rails.root + "spec/support/updating_csv/subsequent_visit/N0020010034234243.xlsx")
      @subsequent_csv.save
    end

    it "creates only 1 report" do
      expect {
        SpreadsheetParsingWorker.perform_async(@subsequent_csv.id)
      }.to change(Report, :count).by(1)
    end

    it "create a new inspection Visit" do
      expect {
        SpreadsheetParsingWorker.perform_async(@subsequent_csv.id)
      }.to change(Visit.where(:parent_visit_id => nil), :count).by(1)
    end
  end

  #-----------------------------------------------------------------------------

  context "when uploading a custom CSV" do

    it "creates 4 new reports" do
      expect {
        SpreadsheetParsingWorker.perform_async(real_csv.id)
      }.to change(Report, :count).by(4)
    end

  end

  #-----------------------------------------------------------------------------

  context "when uploading a custom CSV with inspection AND elimination date" do
    let(:csv_file)       { File.open("spec/support/should_create_elimination_visit.xlsx") }
    let(:csv)            { FactoryGirl.create(:spreadsheet, :csv => csv_file, :user_id => user.id, :location => location) }

    it "creates 2 inspections" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.to change(Inspection, :count).by(2)
    end

    it "creates only 1 visit" do
      expect {
        SpreadsheetParsingWorker.perform_async(csv.id)
      }.to change(Visit, :count).by(1)
    end

    it "creates a positive inspection and a negative inspection with correct positions" do
      SpreadsheetParsingWorker.perform_async(csv.id)

      inspections = Visit.all.first.inspections.order("position ASC")
      expect(inspections.first.identification_type).to eq(Inspection::Types::POSITIVE)
      expect(inspections.last.identification_type).to eq(Inspection::Types::NEGATIVE)

      expect(inspections.first.position).to eq(0)
      expect(inspections.last.position).to eq(1)
    end
  end

  #-----------------------------------------------------------------------------

  context "when uploading custom Nicaraguan CSV" do
    it "sets correct created_at for generated reports" do
      neighborhood = Neighborhood.first
      csv      = File.open(Rails.root + "spec/support/weird_inspection_date_inconsistency.xlsx")
      csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)

      SpreadsheetParsingWorker.perform_async(csv.id)

      expect(Report.count).to eq(6)
      expect(Report.where("DATE(created_at) = '2014-11-19'").count).to eq(2)
      expect(Report.where("DATE(created_at) = '2014-11-24'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2014-12-06'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2014-12-17'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2015-01-12'").count).to eq(1)
    end
  end

  #----------------------------------------------------------------------------

  describe "Harold's graphs" do
    it "returns data that matches Harold's graphs", :wip => true do
      neighborhood = Neighborhood.first
      Dir[Rails.root + "spec/support/nicaragua_csv/*.xlsx"].each do |f|
        csv      = File.open(f)

        location = create(:location, :address => "#{csv.path.split('/')[-1].gsub('.xlsx', '')}", :neighborhood => neighborhood)
        csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)
        SpreadsheetParsingWorker.perform_async(csv.id)
      end

      reports = Report.where(:neighborhood_id => neighborhood.id)
      @visit_ids = reports.joins(:location).pluck("locations.id")

      daily_stats = Visit.calculate_time_series_for_locations(@visit_ids, nil, nil, "daily")


      loc1 = Location.find_by_address("N002001003").id
      loc2 = Location.find_by_address("N002001004").id
      loc3 = Location.find_by_address("N002001007").id

      [
        {:date => "2014-11-15", :result => [ [:positive, [loc2]], [:potential, [loc1]] ]},
        {:date => "2014-11-22", :result => [ [:positive, [loc1, loc3]], [:potential, [loc3, loc2]] ]},
        {:date => "2014-11-24", :result => [ [:positive, []], [:potential, [loc1]]      ]},
        {:date => "2014-11-26", :result => [ [:positive, [loc2]], [:potential, [loc2]]  ]},
        {:date => "2014-12-05", :result => [ [:positive, [loc3]], [:potential, [loc1]]  ]},
        {:date => "2014-12-13", :result => [ [:positive, []], [:potential, [loc1,loc3]] ]},
        {:date => "2015-01-10", :result => [ [:positive, []], [:potential, [loc2]] ]},
        {:date => "2015-01-21", :result => [ [:positive, []], [:potential, [loc2]] ]}
      ].each do |hash|
        stat = daily_stats.find {|ds| ds[:date] == hash[:date]}
        hash[:result].each do |result|
          expect(stat[result[0]][:locations].sort).to eq(result[1].sort)
        end
      end
    end
  end

  #----------------------------------------------------------------------------

  describe "Benchmarking with July", :heavy => true do
    it "returns data that matches Harold's graphs", :wip => true do
      neighborhood = Neighborhood.first
      Dir[Rails.root + "spec/support/july_csvs/*.xlsx"].each do |f|
        csv      = File.open(f)
        address = csv.path.split('/')[-1].gsub('.xlsx', '').gsub(".", "")

        location = create(:location, :address => "#{address}", :neighborhood => neighborhood)
        csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)
        SpreadsheetParsingWorker.perform_async(csv.id)
      end

      @visit_ids = neighborhood.locations.pluck(:id)

      start_time = Time.parse("2015-07-01")
      end_time   = Time.parse("2015-07-31")
      daily_stats = Visit.calculate_time_series_for_locations(@visit_ids, start_time, end_time, "daily")
      daily_stats.each do |hash|
        [:potential, :positive, :negative, :total].each do |key|
          hash[key][:locations] = hash[key][:locations].map {|id| Location.find(id).address}.sort
        end
      end

      # July 7th, 2015
      ["N002002039", "N002002044"].each do |loc|
        expect(daily_stats[0][:positive][:locations]).to include(loc)
      end
      expect(daily_stats[0][:negative][:count]).to eq(21)

      # July 8th, 2015
      expect(daily_stats[1][:positive][:locations]).to eq([])
      "N002001005,  N002001012".split(",  ").each do |loc|
        expect(daily_stats[1][:potential][:locations]).to include(loc)
      end
      expect(daily_stats[1][:negative][:count]).to eq(11)

      # July 18th, 2015
      ["N002002037", "N002004087", "N002004095"].each do |loc|
        expect(daily_stats[2][:positive][:locations]).to include(loc)
      end
      ["N002005118", "N002006126", "N002006127"].each do |loc|
        expect(daily_stats[2][:potential][:locations]).to include(loc)
      end
      expect(daily_stats[2][:negative][:count]).to eq(43)

      # July 25th, 2015
      "N002004104, N002005117".split(", ").each do |loc|
        expect(daily_stats[3][:positive][:locations]).to include(loc)
      end
      "N002001002, N002001013, N002005118, N002005121".split(", ").each do |loc|
        expect(daily_stats[3][:potential][:locations]).to include(loc)
      end
      expect(daily_stats[3][:negative][:count]).to eq(20)


      # July 31st, 2015
      "N002004104, N002002039, N002005118".split(", ").each do |loc|
        expect(daily_stats[4][:positive][:locations]).to include(loc)
      end
      "N002001003, N002003069, N002005121, N002006126".split(", ").each do |loc|
        expect(daily_stats[4][:potential][:locations]).to include(loc)
      end
      expect(daily_stats[4][:negative][:count]).to eq(57)

      # puts JSON.pretty_generate(daily_stats)
    end
  end


  #----------------------------------------------------------------------------

  describe "Benchmarking monthly data with August", :heavy => true do
    it "returns data that matches Harold's graphs", :wip => true do
      Dir[Rails.root + "spec/support/august_csvs/*.xlsx"].each do |f|
        csv      = File.open(f)
        address = csv.path.split('/')[-1].gsub('.xlsx', '').gsub(".", "")

        location = create(:location, :address => "#{address}")
        csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)
        SpreadsheetParsingWorker.perform_async(csv.id)
      end

      @visit_ids = Location.pluck(:id)

      start_time = Time.parse("2015-08-01")
      end_time   = Time.parse("2015-08-31")
      daily_stats = Visit.calculate_time_series_for_locations(@visit_ids, start_time, end_time, "monthly")
      daily_stats.each do |hash|
        [:potential, :positive, :negative, :total].each do |key|
          hash[key][:locations] = hash[key][:locations].map {|id| Location.find(id).address}.sort
        end
      end

      data = daily_stats[0]
      expect(data[:positive][:count]).to eq(12)
      expect(data[:potential][:count]).to eq(9)
      expect(data[:negative][:count]).to eq(68)
      expect(data[:total][:count]).to eq(88)

      ["N002001003",
      "N002002037",
      "N002002039",
      "N002003051",
      "N002003059",
      "N002003062",
      "N002004104",
      "N002005110",
      "N002006126",
      "N002006127",
      "N002006128",
      "N002006132"].each do |pos_loc|
        expect(data[:positive][:locations]).to include(pos_loc)
      end

      ["N002001009",
      "N002001013",
      "N002003070",
      "N002004103",
      "N002005117",
      "N002005121",
      "N002006126",
      "N002006134",
      "N002006137"].each do |pot_loc|
        expect(data[:potential][:locations]).to include(pot_loc)
      end

      ["N002001001",
      "N002001004",
      "N002001007",
      "N002001008",
      "N002001010",
      "N002001011",
      "N002001014",
      "N002001015",
      "N002001016",
      "N002001017",
      "N002001018",
      "N002001019",
      "N002001020",
      "N002001021",
      "N002001022",
      "N002001023",
      "N002001025",
      "N002001026",
      "N002002032",
      "N002002033",
      "N002002034",
      "N002002035",
      "N002002036",
      "N002002038",
      "N002002040",
      "N002002041",
      "N002002042",
      "N002002044",
      "N002002045",
      "N002002046",
      "N002002047",
      "N002002048",
      "N002002049",
      "N002003055",
      "N002003056",
      "N002003057",
      "N002003066",
      "N002003069",
      "N002003071",
      "N002004079",
      "N002004080",
      "N002004081",
      "N002004082",
      "N002004083",
      "N002004084",
      "N002004085",
      "N002004086",
      "N002004087",
      "N002004088",
      "N002004091",
      "N002004092",
      "N002004093",
      "N002004095",
      "N002004096",
      "N002004098",
      "N002005106",
      "N002005109",
      "N002005111",
      "N002005112",
      "N002005113",
      "N002005114",
      "N002005116",
      "N002005118",
      "N002006131",
      "N002006133",
      "N002006136",
      "N002006138",
      "N002006140"].each do |loc|
        expect(data[:negative][:locations]).to include(loc)
      end
    end
  end

  #----------------------------------------------------------------------------

  context "when uploading custom CSV with labels" do
    before(:each) do
      csv      = File.open(Rails.root + "spec/support/barrel_labeling.xlsx")
      csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)

      SpreadsheetParsingWorker.perform_async(csv.id)
    end

    it "doesn't create duplicate reports" do
      expect(Report.count).to eq(3)
    end

    it "creates additional Inspection instances for same report" do
      r = Report.find_by_field_identifier("b3")
      expect(r.inspections.count).to eq(5)
    end

    it "creates Inspection instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      inspections = r.inspections.order("position ASC")
      expect(inspections[0].identification_type).to eq(Inspection::Types::POTENTIAL)
      expect(inspections[1].identification_type).to eq(Inspection::Types::POTENTIAL)
      expect(inspections[2].identification_type).to eq(Inspection::Types::POSITIVE)
      expect(inspections[3].identification_type).to eq(Inspection::Types::POSITIVE)
      expect(inspections[4].identification_type).to eq(Inspection::Types::NEGATIVE)
    end

    it "creates additional Visit instances for same report" do
      r = Report.find_by_field_identifier("b3")
      expect(r.visits.count).to eq(4)
    end

    it "creates Visit instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      r.save(:validate => false)
      visits = r.visits.order("visited_at ASC")

      v = Visit.find_or_create_visit_for_location_id_and_date(r.location_id, r.eliminated_at)
      r.update_inspection_for_visit(v)

      # NOTE: We're expecting 4 but the last one will not be created until it's "completed"!
      expect(visits[0].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-01")
      expect(visits[1].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-03")
      expect(visits[2].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-05")
      expect(visits[3].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-07")

    end
  end

  #-----------------------------------------------------------------------------

  # Harold notices when uploading the specific CSV, duplicate reports were generated.
  describe "Ensure no duplicate reports" do
    before(:each) do
      csv      = File.open(Rails.root + "spec/support/duplicate_reports_generated.xlsx")
      csv = FactoryGirl.create(:spreadsheet, :csv => csv, :user_id => user.id, :location => location)

      SpreadsheetParsingWorker.perform_async(csv.id)
    end


    it "creates 5 distinct barrel reports" do
      expect(Report.count).to eq(5)
    end

    it "creates 1 visit" do
      expect(Visit.count).to eq(1)
    end

    it "creates 5 inspections" do
      expect(Inspection.count).to eq(5)
    end
  end

end
