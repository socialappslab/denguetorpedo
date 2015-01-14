# encoding: utf-8
require 'spec_helper'

describe CsvReportsController do
  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:csv) 			      { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:uploaded_csv)    { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }

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

    it "creates a new CSV file" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(CsvReport, :count).by(1)
    end

    it "creates 3 new reports" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(Report, :count).by(3)
    end

    it "creates 3 new location_statuses" do
      expect {
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      }.to change(LocationStatus, :count).by(3)
    end


    describe "the parsed Report attributes" do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      end


      it "correctly sets inspection date" do
        r = Report.order("id").first
        r.created_at.strftime("%Y-%m-%d").should eq("2014-12-24")
      end

      it "correctly sets elimination date" do
        r = Report.order("id")[1]
        r.eliminated_at.strftime("%Y-%m-%d").should eq("2014-12-26")
      end

      it "doesn't set completion date" do
        Report.find_each do |r|
          r.completed_at.should eq(nil)
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


    describe "the parsed LocationStatus attributes", :after_commit => true do
      before(:each) do
        post :create, :csv_report => { :csv => uploaded_csv },
        :report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501,
        :neighborhood_id => Neighborhood.first.id
      end

      it "correctly sets status" do
        ls = LocationStatus.where("DATE(created_at) = ?", "2014-12-24").first
        expect(ls.status).to eq(LocationStatus::Types::POSITIVE)

        # NOTE: These should be positive since the above location status is positive,
        # and still hasn't been eliminated.
        ls = LocationStatus.where("DATE(created_at) = ?", "2014-12-31").first
        expect(ls.status).to eq(LocationStatus::Types::POSITIVE)

        # TODO: Perhaps we should instead think of LocationStatus as Visits that
        # essentially categorize each visit as POSITIVE, POTENTIAL, or NEGATIVE.
        # The status of a location is then dependent on whether each visit resolved
        # its status... We would need to define what "resolved" means in this context.
        ls = LocationStatus.where("DATE(created_at) = ?", "2015-01-10").first
        expect(ls.status).to eq(LocationStatus::Types::POTENTIAL)
      end

      it "correctly sets dengue and chik count" do
        ls = LocationStatus.where("DATE(created_at) = ?", "2014-12-24").first
        expect(ls.chik_count).to eq(3)
        expect(ls.dengue_count).to eq(5)

        ls = LocationStatus.where("DATE(created_at) = ?", "2014-12-31").first
        expect(ls.chik_count).to eq(1)
        expect(ls.dengue_count).to eq(1)

        ls = LocationStatus.where("DATE(created_at) = ?", "2015-01-10").first
        expect(ls.chik_count).to eq(0)
        expect(ls.dengue_count).to eq(0)
      end
    end
  end

  #-----------------------------------------------------------------------------

end
