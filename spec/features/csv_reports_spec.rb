# -*- encoding : utf-8 -*-
require "rails_helper"

describe "CsvReports", :type => :feature do
  let(:user) 		 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:location) { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)     { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let!(:csv)     { Rails.root + "spec/support/csv/inspection_date_in_future.xlsx" }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    I18n.locale = User::Locales::SPANISH
    sign_in(user)
  end

  it "uploads successfully" do
    visit new_csv_report_path

    expect {
      page.find("#report_location_attributes_latitude", :visible => false).set(12)
      page.find("#report_location_attributes_longitude", :visible => false).set(12)
      attach_file "csv_report_csv", csv
      page.find(".submit-button").click
    }.to change(CsvReport, :count).by(1)

  end

  #---------------------------------------------------------------------------

  describe "uploading CSVs with errors", :js => true do
    before(:each) do
      visit new_csv_report_path
    end

    it "displays an error" do
      attach_file "csv_report_csv", csv
      page.find(".submit-button").click
      sleep 0.2
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.missing_location") )
    end
  end

  #---------------------------------------------------------------------------

  describe "Viewing all CSVs" do
    before(:each) do
      5.times do
        FactoryGirl.create(:csv_report, :user_id => user.id)
      end

      CsvReport.last.update_column(:parsed_at, Time.zone.now)
      visit csv_reports_path
    end

    it "displays parsing for non-parsed CSV" do
      (1..4).each do |index|
        expect( page.all("tr")[index] ).to have_content("Parsing")
      end
    end

    it "displays needs verification for parsed CSV" do
      skip "TODO"
    end

    it "display View for verified CSV" do
      expect(page.all("tr")[0]).to have_content("View")
    end

    it "displays only your CSV" do
      u = FactoryGirl.create(:user)
      FactoryGirl.create(:csv_report, :user => u, :csv_file_name => "test")
      expect(page).not_to have_content("test")
    end
  end

  #---------------------------------------------------------------------------

  describe "Viewing a CSV" do
    # describe "verified CSV" do
    #   it "TODO" do
    #     pending
    #   end
    # end
    #
    # describe "parsed but not verified CSV" do
    #   it "TODO" do
    #     pending
    #   end
    # end

    describe "with Errors" do
      let(:default_params) { {:report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501, :neighborhood_id => Neighborhood.first.id} }

      before(:each) do
        Sidekiq::Testing.inline!
      end

      after(:each) do
        Sidekiq::Testing.fake!
      end

      it "clicking delete CSV will delete the CSV" do
        csv = File.open(Rails.root + "spec/support/foco_marcado.jpg")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect {
          click_button "Delete CSV"
        }.to change(CsvReport, :count).by(-1)
      end

      it "clicking delete CSV will delete all CsvErrors" do
        csv = File.open(Rails.root + "spec/support/foco_marcado.jpg")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(csv)
        expect {
          click_button "Delete CSV"
        }.to change(CsvError, :count).by(-1)
      end

      it "displays unknown format error" do
        csv = FactoryGirl.create(:csv_report, :csv => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::UNKNOWN_FORMAT] )
      end

      it "displays missing house error" do
        csv = File.open("spec/support/csv/missing_house.csv")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::MISSING_HOUSE] )
      end

      it "displays unknown code error" do
        csv = File.open("spec/support/csv/unknown_code.csv")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::UNKNOWN_CODE] )
      end

      it "displays inspection date in future error" do
        csv = File.open("spec/support/csv/inspection_date_in_future.xlsx")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::VISIT_DATE_IN_FUTURE] )
      end

      it "displays elimination date in future error" do
        csv = File.open("spec/support/csv/elimination_date_in_future.xlsx")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(csv)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::ELIMINATION_DATE_IN_FUTURE] )
      end

      it "displays elimination date before inspection date error" do
        csv = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
        csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id)
        CsvParsingWorker.perform_async(csv.id, default_params)

        visit csv_report_path(CsvReport.last)
        expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE] )
      end

    end
  end

  #---------------------------------------------------------------------------

end
