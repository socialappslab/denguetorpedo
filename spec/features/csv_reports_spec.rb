# encoding: utf-8
require 'spec_helper'

describe "CsvReports", :type => :feature do
  let(:user) 		 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:location) { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)     { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let!(:csv)     { Rails.root + "spec/support/csv/inspection_date_in_future.xlsx" }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    I18n.default_locale = User::Locales::SPANISH
    sign_in(user)
  end

  #---------------------------------------------------------------------------

  describe "uploading CSVs with errors" do
    before(:each) do
      visit new_neighborhood_csv_report_path(Neighborhood.first)
    end

    it "notifies user that location is missing" do
      # page.find("#csv_report_csv").set(csv)
      attach_file "csv_report_csv", csv
      page.find(".submit-button").click
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.missing_location") )
    end

    it "notifies user that inspection date is in the future" do
      page.find("#report_location_attributes_latitude", :visible => false).set(0)
      page.find("#report_location_attributes_longitude", :visible => false).set(0)
      attach_file "csv_report_csv", csv
      page.find(".submit-button").click
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.inspection_date_in_future") )
    end

    it "notifies user that elimination date is in the future" do
      page.find("#report_location_attributes_latitude", :visible => false).set(0)
      page.find("#report_location_attributes_longitude", :visible => false).set(0)
      attach_file "csv_report_csv", Rails.root + "spec/support/csv/elimination_date_in_future.xlsx"
      page.find(".submit-button").click
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.elimination_date_in_future") )
    end

    it "notifies user that elimination date is before inspection date" do
      page.find("#report_location_attributes_latitude", :visible => false).set(0)
      page.find("#report_location_attributes_longitude", :visible => false).set(0)
      attach_file "csv_report_csv", Rails.root + "spec/support/csv/elimination_date_before_inspection_date.xlsx"
      page.find(".submit-button").click
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.elimination_date_before_inspection_date") )
    end

  end

  #---------------------------------------------------------------------------

end
