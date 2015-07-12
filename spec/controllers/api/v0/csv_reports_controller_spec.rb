# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::CsvReportsController do
  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:csv) 			      { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:uploaded_csv)    { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }
  let(:real_csv)        { ActionDispatch::Http::UploadedFile.new(:tempfile => File.open("spec/support/pruebaAutoreporte4.xlsx"), :filename => File.basename(csv)) }

  #-----------------------------------------------------------------------------

  context "when uploading a CSV" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "correctly sets the location address" do
      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => Neighborhood.first.id

      l = Location.last
      expect(l.address).to eq("N123456")
    end

    it "sets parsed_at" do
      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => Neighborhood.first.id

      expect(CsvReport.last.parsed_at).not_to eq(nil)
    end

    it "creates a new CSV file" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(CsvReport, :count).by(1)
    end

    it "associates the CSV with the user" do
      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => Neighborhood.first.id

      csv = CsvReport.last
      expect(csv.user_id).to eq(user.id)
    end

    it "creates 3 new reports" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(3)
    end

    #--------------------------------------------------------------------------

    describe "with Errors" do
      render_views

      it "notifies user that inspection date is in the future" do
        csv      = File.open("spec/support/csv/inspection_date_in_future.xlsx")
        file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

        post :create, :csv_report => { :csv => file_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id

        expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.inspection_date_in_future") )
      end

      it "notifies user that elimination date is in the future" do
        csv      = File.open("spec/support/csv/elimination_date_in_future.xlsx")
        file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

        post :create, :csv_report => { :csv => file_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id

        expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.elimination_date_in_future") )
      end

      it "notifies user that elimination date is before inspection date" do
        csv      = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
        file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

        post :create, :csv_report => { :csv => file_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id

        expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.elimination_date_before_inspection_date") )
      end
    end

    #--------------------------------------------------------------------------

    describe "the parsed Report attributes" do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
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

    #--------------------------------------------------------------------------

    describe "the parsed Visit attributes", :after_commit => true do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
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
  end

  context "when uploading the same CSV", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      post :create, :csv_report => { :csv => uploaded_csv },
      :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
      :neighborhood_id => Neighborhood.first.id
    end

    it "reuses the same location" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Location, :count)
    end

    it "does not create new CsvReport" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(CsvReport, :count)
    end

    it "does NOT create new reports" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Report, :count)
    end

    it "does NOT create new Visit" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Visit, :count)
    end
  end

  context "when uploading the same but updated CSV", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      csv = "spec/support/updating_csv/initial_visit.xlsx"
      initial_csv = ActionDispatch::Http::UploadedFile.new(:tempfile => File.open(csv), :filename => File.basename(csv))

      post :create, :csv_report => { :csv => initial_csv },
      :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
      :neighborhood_id => user.neighborhood.id

      csv = "spec/support/updating_csv/subsequent_visit.xlsx"
      @subsequent_csv = ActionDispatch::Http::UploadedFile.new(:tempfile => File.open(csv), :filename => File.basename(csv))
    end

    it "reuses the same location" do
      expect {
        post :create, :csv_report => { :csv => @subsequent_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.not_to change(Location, :count)
    end

    it "creates only 1 report" do
      expect {
        post :create, :csv_report => { :csv => @subsequent_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(1)
    end

    it "create a new inspection Visit" do
      expect {
        post :create, :csv_report => { :csv => @subsequent_csv },
        :report_location_attributes_latitude => 12, :report_location_attributes_longitude => -86,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Visit, :count).by(1)
    end
  end


  #-----------------------------------------------------------------------------

  context "when uploading a custom CSV" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "creates 4 new reports" do
      expect {
        post :create, :csv_report => { :csv => real_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(4)
    end

  end

  #-----------------------------------------------------------------------------

  context "when uploading custom Nicaraguan CSV", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "sets correct created_at for generated reports" do
      neighborhood = Neighborhood.first
      csv      = File.open(Rails.root + "spec/support/weird_inspection_date_inconsistency.xlsx")
      csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, :csv_report => { :csv => csv_file },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => neighborhood.id

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
        csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

        post :create, :csv_report => { :csv => csv_file },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => neighborhood.id
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

  context "when uploading custom CSV with labels", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      neighborhood = Neighborhood.first
      csv      = File.open(Rails.root + "spec/support/barrel_labeling.xlsx")
      csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, :csv_report => { :csv => csv_file },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => neighborhood.id
    end

    it "doesn't create duplicate reports" do
      expect(Report.count).to eq(3)
    end

    it "creates Report instances with correct attributes" do
    end

    it "creates additional Inspection instances for same report" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)
      inspections = Inspection.where(:report_id => r.id)
      expect(inspections.count).to eq(4)
    end

    it "creates Inspection instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)
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
      expect(r.visits.count).to eq(4)
    end

    it "creates Visit instances with correct attributes" do
      r = Report.find_by_field_identifier("b3")
      r.completed_at = Time.zone.now
      r.save(:validate => false)
      visits = r.visits.order("visited_at ASC")

      # NOTE: We're expecting 4 but the last one will not be created until it's "completed"!
      expect(visits[0].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-01")
      expect(visits[1].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-03")
      expect(visits[2].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-05")
      expect(visits[3].visited_at.strftime("%Y-%m-%d")).to eq("2015-05-07")

    end
  end

  #----------------------------------------------------------------------------

  context "asking for photos", :after_commit => true do
    before(:each) do
      cookies[:auth_token] = user.auth_token

      neighborhood = Neighborhood.first
      csv      = File.open(Rails.root + "spec/support/ask_for_photo.xlsx")
      csv_file = ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, :csv_report => { :csv => csv_file },
      :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
      :neighborhood_id => neighborhood.id
    end

    it "should ask for photo" do
    end
  end


end
