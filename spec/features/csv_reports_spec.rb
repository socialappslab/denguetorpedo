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
      attach_file "spreadsheet_csv", csv
      page.find(".submit-button").click
    }.to change(Spreadsheet, :count).by(1)

  end

  #---------------------------------------------------------------------------

  describe "uploading CSVs with errors", :js => true do
    before(:each) do
      visit new_csv_report_path
    end

    it "displays an error" do
      attach_file "spreadsheet_csv", csv
      page.find(".submit-button").click
      sleep 0.2
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.missing_location") )
    end
  end

  #---------------------------------------------------------------------------

  describe "Viewing all CSVs" do
    before(:each) do
      5.times do
        FactoryGirl.create(:spreadsheet, :user_id => user.id)
      end

      Spreadsheet.last.update_column(:parsed_at, Time.zone.now)
      visit csv_reports_path
    end

    it "displays parsing for non-parsed CSV" do
      expect( page ).to have_content( I18n.t("views.csv_reports.parsing") )
    end

    it "display View for verified CSV" do
      Spreadsheet.last.update_column(:verified_at, Time.zone.now)
      visit csv_reports_path
      expect(page.all("tr")[0]).to have_content( "Editar" )
    end

    it "displays only your CSV" do
      u = create(:user)
      create(:spreadsheet, :user => u, :csv_file_name => "test")
      expect(page).not_to have_content("test")
    end
  end

  #---------------------------------------------------------------------------

end
