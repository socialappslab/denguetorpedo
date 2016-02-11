# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::CsvReportsController do
  render_views

  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:csv) 			      { File.open("spec/support/forma_csv_examples.xlsx") }
  let(:uploaded_csv)    { ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv)) }
  let(:real_csv)        { ActionDispatch::Http::UploadedFile.new(:tempfile => File.open("spec/support/pruebaAutoreporte4.xlsx"), :filename => File.basename(csv)) }
  let(:csv_params)      {
    {:spreadsheet => { :csv => uploaded_csv },
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
    }.to change(Spreadsheet, :count).by(1)
  end

  it "creates a new location" do
    expect {
      post :create, csv_params
    }.to change(Location, :count).by(1)
  end

  it "creates a location with proper attributes" do
    post :create, csv_params
    l = Location.last
    expect(l.address).to eq("forma_csv_examples")
    expect(l.latitude).to eq(12.1308585524794)
    expect(l.longitude).to eq(-86.280598641315)
  end

  it "uses an existing location if address exists" do
    create(:location, :address => "forma_csv_examples")
    expect {
      post :create, csv_params
    }.not_to change(Location, :count)
  end

  it "associates the CSV with the user" do
    post :create, csv_params

    csv = Spreadsheet.last
    expect(csv.user_id).to eq(user.id)
  end

  it "queues a CsvParsingJob" do
    expect {
      post :create, csv_params
    }.to change(SpreadsheetParsingWorker.jobs, :count).by(1)
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
    create(:spreadsheet, :csv => csv)
    expect {
      post :create, csv_params
    }.not_to change(Spreadsheet, :count)
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

    it "returns missing CSV error" do
      post :create, csv_params.merge(:spreadsheet => {})
      expect( JSON.parse(response.body)["message"] ).to eq( I18n.t("views.csv_reports.flashes.unknown_format") )
    end
  end

  #--------------------------------------------------------------------------

  describe "Updating a CSV" do
    let!(:csv)      { FactoryGirl.build(:parsed_csv, :user => user) }

    before(:each) do
      csv.save(:validate => false)
    end

    it "updates user ID" do
      put :update, :id => csv.id, :spreadsheet => {:user_id => 1}
      expect(csv.reload.user_id).to eq(1)
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
  end

  #--------------------------------------------------------------------------

  describe "Destroying a CSV" do
    it "changes CsvReport" do
      csv =  build(:parsed_csv, :user => user)
      csv.save(:validate => false)

      expect {
        delete :destroy, :id => csv.id
      }.to change(Spreadsheet, :count).by(-1)
    end
  end
  #--------------------------------------------------------------------------

  describe "Uploading CSV in batch" do
    before(:each) do
      @multiple_csvs = []
      Dir["spec/support/nicaragua_csv/*.xlsx"].each do |csv|
        filename = File.basename(csv).split("/").last.split(".").first.strip
        loc = create(:location, :address => filename)
        csv_report = FactoryGirl.build(:parsed_csv, :location => loc, :user => user, :csv => Rack::Test::UploadedFile.new(csv, 'text/csv'))
        csv_report.save(:validate => false)

        csv = File.open(csv)
        @multiple_csvs << ActionDispatch::Http::UploadedFile.new(:tempfile => csv, :filename => File.basename(csv))
      end
    end

    after(:each) do
      SpreadsheetParsingWorker.drain
    end

    around(:each) do |example|
      Sidekiq::Testing.fake! do
        example.run
      end
    end

    it "creates N Sidekiq jobs" do
      expect {
        post :batch, :multiple_csv => @multiple_csvs
      }.to change(SpreadsheetParsingWorker.jobs, :count).by(3)
    end

    it "doesn't create new CSVs" do
      expect {
        post :batch, :multiple_csv => @multiple_csvs
      }.not_to change(Spreadsheet, :count)
    end

    describe "with errors" do
      before(:each) do
        Location.last.destroy
      end

      it "complains if location can't be found for a CSV" do
        post :batch, :multiple_csv => @multiple_csvs
        expect( JSON.parse(response.body)["message"] ).to include( "¡Uy! No se pudo encontrar lugar para" )
      end

      it "doesn't create any Sidekiq jobs" do
        expect {
          post :batch, :multiple_csv => @multiple_csvs
        }.not_to change(SpreadsheetParsingWorker.jobs, :count)
      end
    end
  end


  #--------------------------------------------------------------------------

end
