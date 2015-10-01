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
      fill_in "location[address]", :with => "Test"
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
        expect( page.all("tr")[index + 1] ).to have_content( I18n.t("views.csv_reports.parsing") )
      end
    end

    it "display View for verified CSV" do
      CsvReport.last.update_column(:verified_at, Time.zone.now)
      visit csv_reports_path
      expect(page.all("tr")[1]).to have_content( I18n.t("views.csv_reports.view") )
    end

    it "displays only your CSV" do
      u = FactoryGirl.create(:user)
      FactoryGirl.create(:csv_report, :user => u, :csv_file_name => "test")
      expect(page).not_to have_content("test")
    end
  end

  #---------------------------------------------------------------------------

end
