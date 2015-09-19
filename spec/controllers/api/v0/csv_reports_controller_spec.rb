# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::CsvReportsController do
  render_views

  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:csv) 			      { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:uploaded_csv)    { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }
  let(:real_csv)        { ActionDispatch::Http::UploadedFile.new(:tempfile => File.open("spec/support/pruebaAutoreporte4.xlsx"), :filename => File.basename(csv)) }
  let(:csv_params)      {
    {:csv_report => { :csv => uploaded_csv },
    :location => {:address => "Test"},
    :report_location_attributes_latitude => 12.1308585524794,
    :report_location_attributes_longitude => -86.28059864131501,
    :neighborhood_id => Neighborhood.first.id}
  }

  #-----------------------------------------------------------------------------

  before(:each) do
    cookies[:auth_token] = user.auth_token
    Sidekiq::Testing.fake!
  end

  it "creates a new CSV file" do
    expect {
      post :create, csv_params
    }.to change(CsvReport, :count).by(1)
  end

  it "creates a new location" do
    expect {
      post :create, csv_params
    }.to change(Location, :count).by(1)
  end

  it "creates a location with proper attributes" do
    post :create, csv_params
    l = Location.last
    expect(l.address).to eq("Test")
    expect(l.latitude).to eq(12.1308585524794)
    expect(l.longitude).to eq(-86.280598641315)
  end

  it "uses an existing location if address exists" do
    create(:location, :address => "Test")
    expect {
      post :create, csv_params
    }.not_to change(Location, :count)
  end

  it "associates the CSV with the user" do
    post :create, csv_params

    csv = CsvReport.last
    expect(csv.user_id).to eq(user.id)
  end

  it "associates the CSV with the neighborhood" do
    n = FactoryGirl.create(:neighborhood)
    post :create, csv_params.merge(:neighborhood_id => n.id)

    csv = CsvReport.last
    expect(csv.neighborhood_id).to eq(n.id)
  end

  it "queues a CsvParsingJob" do
    expect {
      post :create, csv_params
    }.to change(CsvParsingWorker.jobs, :count).by(1)
  end

  it "creates a location with correct neighborhood" do
    Sidekiq::Testing.inline!
    n = FactoryGirl.create(:neighborhood, :name => "Test Neighborhood", :city_id => 1)
    post :create, csv_params.merge(:neighborhood_id => n.id)

    expect(Location.last.neighborhood_id).to eq(n.id)
  end

  it "redirects to CSV#index path" do
    post :create, csv_params
    expect( JSON.parse(response.body)["redirect_path"] ).to eq( csv_reports_path )
  end

  it "doesn't create new CSV if filenames match" do
    create(:csv_report, :csv => csv)
    expect {
      post :create, csv_params
    }.not_to change(CsvReport, :count)
  end

  #--------------------------------------------------------------------------

  describe "with Errors" do
    let(:csv)      { File.open("spec/support/csv/inspection_date_in_future.xlsx") }
    let(:file_csv) { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }

    it "returns missing location attributes error" do
      csv      = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
      file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, csv_params.merge(:report_location_attributes_latitude => nil)
      expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.missing_location") )
    end

    it "fails on missing location" do
      csv      = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
      file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, csv_params.merge(:location => {:address => ""})
      expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.missing_address") )
    end

    it "returns missing CSV error" do
      csv      = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
      file_csv =  ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))

      post :create, csv_params.merge(:csv_report => {})
      expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.unknown_format") )
    end
  end

  #--------------------------------------------------------------------------

  describe "Updating a CSV" do
    let!(:csv)      { FactoryGirl.build(:parsed_csv, :user => user) }

    before(:each) do
      csv.save(:validate => false)
    end

    it "updates location address" do
      put :update, :id => csv.id, :location => { :address => "Haha", :neighborhood_id => 100 }
      expect(csv.location.reload.address).to eq("Haha")
    end

    it "updates location neighborhood" do
      put :update, :id => csv.id, :location => { :address => "Haha", :neighborhood_id => 100  }
      expect(csv.location.reload.neighborhood_id).to eq(100)
    end
  end

  #--------------------------------------------------------------------------

  describe "Verifying a CSV" do
    let!(:csv)      { FactoryGirl.build(:parsed_csv, :user => user) }

    before(:each) do
      csv.save(:validate => false)
    end

    it "sets verified_at column" do
      put :verify, :id => csv.id
      expect(csv.reload.verified_at).not_to eq(nil)
    end

    it "returns proper redirect path" do
      put :verify, :id => csv.id
      expect( JSON.parse(response.body)["redirect_path"] ).to eq( csv_report_path(csv) )
    end
  end

  #--------------------------------------------------------------------------

end
