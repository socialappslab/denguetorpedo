# -*- encoding : utf-8 -*-
require "rails_helper"

describe CsvParsingWorker do
  let(:user) 		       { FactoryGirl.create(:user) }
  let(:csv_file)       { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:real_csv_file)  { File.open("spec/support/pruebaAutoreporte4.xlsx") }
  let(:location)       { create(:location, :address => "N123456") }
  let(:csv)            { FactoryGirl.create(:csv_report, :csv => csv_file, :user_id => user.id, :location => location) }
  let(:real_csv)       { FactoryGirl.create(:csv_report, :csv => real_csv_file, :user_id => user.id, :location => location) }

  before(:each) do
    Sidekiq::Testing.inline!
  end

  it "sets parsed_at" do
    CsvParsingWorker.perform_async(csv.id)
    expect(CsvReport.last.parsed_at).not_to eq(nil)
  end

  it "creates a new CSV file" do
    expect {
      CsvParsingWorker.perform_async(csv.id)
    }.to change(CsvReport, :count).by(1)
  end

  it "associates the CSV with the user" do
    CsvParsingWorker.perform_async(csv.id)
    expect(CsvReport.last.user_id).to eq(user.id)
  end

  it "creates 3 new reports" do
    expect {
      CsvParsingWorker.perform_async(csv.id)
    }.to change(Report, :count).by(3)
  end

  it "current visit date of specific row is properly parsed" do
    # The specific bug here was that a valid visit date was completely ignored
    # because the row didn't have a breeding site. The correct solution is to
    # parse and store the visit date, and then make a decision on whether to
    # proceed or not to next row.
    csv = File.open("spec/support/csv/visit_date_row_bug.xlsx")
    csv = FactoryGirl.create(:csv_report, :csv => csv, :location => location)
    CsvParsingWorker.perform_async(csv.id)
    csv = CsvReport.last
    expect(csv.parsed_at).not_to eq(nil)
  end

  #----------------------------------------------------------------------------

  describe "with errors" do
    it "creates wrong format error" do
      csv = FactoryGirl.create(:csv_report, :csv => File.open(Rails.root + "spec/support/foco_marcado.jpg"))
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNKNOWN_FORMAT)
    end

    it "returns missing house error" do
      csv = File.open("spec/support/csv/missing_house.csv")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::MISSING_HOUSE)
    end

    it "returns unknown code error" do
      csv = File.open("spec/support/csv/unknown_code.csv")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNKNOWN_CODE)
    end

    it "returns visit date in future error" do
      csv = File.open("spec/support/csv/inspection_date_in_future.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::VISIT_DATE_IN_FUTURE)
    end

    it "returns elimination date in future error" do
      csv = File.open("spec/support/csv/elimination_date_in_future.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::ELIMINATION_DATE_IN_FUTURE)
    end

    it "returns elimination date before visit date error" do
      csv = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE)
    end

    it "returns unparseable date error" do
      csv = File.open("spec/support/csv/unparseable_datetime.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv)
      CsvParsingWorker.perform_async(csv.id)
      error = CsvError.last
      expect(error.csv_report_id).to eq(csv.id)
      expect(error.error_type).to eq(CsvError::Types::UNPARSEABLE_DATE)
    end
  end

  #----------------------------------------------------------------------------

  describe "the parsed Visit attributes", :after_commit => true do
    before(:each) do
      CsvParsingWorker.perform_async(csv.id)
    end

    it "creates 3 inspection visits" do
      expect(Visit.where(:parent_visit_id => nil).count).to eq(3)
    end

    it "creates no follow-up visits" do
      expect(Visit.where("parent_visit_id IS NOT NULL").count).to eq(0)
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
      CsvParsingWorker.perform_async(csv.id)
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
      CsvParsingWorker.perform_async(csv.id)
    end

    it "reuses the same location" do
      expect {
        CsvParsingWorker.perform_async(csv.id)
      }.not_to change(Location, :count)
    end

    it "does not create new CsvReport" do
      expect {
        CsvParsingWorker.perform_async(csv.id)
      }.not_to change(CsvReport, :count)
    end

    it "does NOT create new reports" do
      expect {
        CsvParsingWorker.perform_async(csv.id)
      }.not_to change(Report, :count)
    end

    it "does NOT create new Visit" do
      expect {
        CsvParsingWorker.perform_async(csv.id)
      }.not_to change(Visit, :count)
    end
  end

  #-----------------------------------------------------------------------------

  context "when uploading the same but updated CSV", :after_commit => true do
    before(:each) do
      csv = FactoryGirl.create(:csv_report, :csv => File.open(Rails.root + "spec/support/updating_csv/initial_visit.xlsx"), :location => location)
      CsvParsingWorker.perform_async(csv.id)

      @subsequent_csv = FactoryGirl.create(:csv_report, :csv => File.open(Rails.root + "spec/support/updating_csv/subsequent_visit.xlsx"), :location => location)
    end

    it "creates only 1 report" do
      expect {
        CsvParsingWorker.perform_async(@subsequent_csv.id)
      }.to change(Report, :count).by(1)
    end

    it "create a new inspection Visit" do
      expect {
        CsvParsingWorker.perform_async(@subsequent_csv.id)
      }.to change(Visit, :count).by(1)
    end
  end

  #-----------------------------------------------------------------------------

  context "when uploading a custom CSV" do

    it "creates 4 new reports" do
      expect {
        CsvParsingWorker.perform_async(real_csv.id)
      }.to change(Report, :count).by(4)
    end

  end

  #-----------------------------------------------------------------------------

  context "when uploading custom Nicaraguan CSV", :after_commit => true do
    it "sets correct created_at for generated reports" do
      neighborhood = Neighborhood.first
      csv      = File.open(Rails.root + "spec/support/weird_inspection_date_inconsistency.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)

      CsvParsingWorker.perform_async(csv.id)

      expect(Report.count).to eq(6)
      expect(Report.where("DATE(created_at) = '2014-11-19'").count).to eq(2)
      expect(Report.where("DATE(created_at) = '2014-11-24'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2014-12-06'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2014-12-17'").count).to eq(1)
      expect(Report.where("DATE(created_at) = '2015-01-12'").count).to eq(1)
    end

    it "returns data that matches Harold's graphs" do
      neighborhood = Neighborhood.first
      Dir[Rails.root + "spec/support/nicaragua_csv/*.xlsx"].each do |f|
        csv      = File.open(f)

        location = create(:location, :address => "#{csv.path}", :neighborhood => neighborhood)
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location, :neighborhood => neighborhood)
        CsvParsingWorker.perform_async(csv.id)
      end

      reports = Report.where(:neighborhood_id => neighborhood.id)
      @visit_ids = reports.joins(:location).pluck("locations.id")

      daily_stats = Visit.calculate_status_distribution_for_locations(@visit_ids, nil, nil, "daily")

      stat = daily_stats.find {|ds| ds[:date] == "2014-11-15"}
      expect(stat).to eq ({
        :date => "2014-11-15",
        :positive => {:count=>1, :percent=>33},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>1, :percent=>33},
        :total => {:count=>3}
      })


      stat = daily_stats.find {|ds| ds[:date] == "2014-11-22"}
      expect(stat).to eq ({
        :date => "2014-11-22",
        :positive => {:count=>2, :percent=>67},
        :potential => {:count=>2, :percent=>67},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>3}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-11-24"}
      expect(stat).to eq ({
        :date => "2014-11-24",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>50},
        :negative => {:count=>1, :percent=>50},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-11-26"}
      expect(stat).to eq ({
        :date => "2014-11-26",
        :positive => {:count=>1, :percent=>100},
        :potential => {:count=>1, :percent=>100},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>1}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-12-05"}
      expect(stat).to eq ({
        :date => "2014-12-05",
        :positive => {:count=>1, :percent=>50},
        :potential => {:count=>1, :percent=>50},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2014-12-13"}
      expect(stat).to eq ({
        :date => "2014-12-13",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>2, :percent=>100},
        :negative => {:count=>0, :percent=>0},
        :total => {:count=>2}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2015-01-10"}
      expect(stat).to eq ({
        :date => "2015-01-10",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>2, :percent=>67},
        :total => {:count=>3}
      })

      stat = daily_stats.find {|ds| ds[:date] == "2015-01-21"}
      expect(stat).to eq ({
        :date => "2015-01-21",
        :positive => {:count=>0, :percent=>0},
        :potential => {:count=>1, :percent=>33},
        :negative => {:count=>2, :percent=>67},
        :total => {:count=>3}
      })

    end
  end

  #----------------------------------------------------------------------------

  context "when uploading custom CSV with labels" do
    before(:each) do
      csv      = File.open(Rails.root + "spec/support/barrel_labeling.xlsx")
      csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)

      CsvParsingWorker.perform_async(csv.id)
    end

    it "doesn't create duplicate reports" do
      expect(Report.count).to eq(3)
    end

    it "creates additional Inspection instances for same report" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)

      v = r.find_or_create_elimination_visit()
      r.update_inspection_for_visit(v)

      inspections = Inspection.where(:report_id => r.id)
      expect(inspections.count).to eq(4)
    end

    it "creates Inspection instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)

      v = r.find_or_create_elimination_visit()
      r.update_inspection_for_visit(v)


      inspections = Inspection.where(:report_id => r.id).joins(:visit).order("visits.visited_at ASC")
      expect(inspections[0].identification_type).to eq(Inspection::Types::POTENTIAL)
      expect(inspections[1].identification_type).to eq(Inspection::Types::POTENTIAL)
      expect(inspections[2].identification_type).to eq(Inspection::Types::POSITIVE)
      expect(inspections[3].identification_type).to eq(Inspection::Types::NEGATIVE)
    end

    it "creates additional Visit instances for same report" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)

      v = r.find_or_create_elimination_visit()
      r.update_inspection_for_visit(v)

      expect(r.visits.count).to eq(4)
    end

    it "creates Visit instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)
      visits = r.visits.order("visited_at ASC")

      v = r.find_or_create_elimination_visit()
      r.update_inspection_for_visit(v)

      # NOTE: We're expecting 4 but the last one will not be created until it's "completed"!
      expect(visits[0].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-01")
      expect(visits[1].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-03")
      expect(visits[2].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-05")
      expect(visits[3].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-07")

    end
  end

  #----------------------------------------------------------------------------

end
