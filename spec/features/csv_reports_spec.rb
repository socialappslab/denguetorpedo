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

  #---------------------------------------------------------------------------

  describe "uploading CSVs with errors", :js => true do
    before(:each) do
      visit new_neighborhood_csv_report_path(Neighborhood.first)
    end

    it "displays an error" do
      attach_file "csv_report_csv", csv
      page.find(".submit-button").click
      sleep 0.2
      expect(page).to have_content( I18n.t("views.csv_reports.flashes.missing_location") )
    end

  end

  #---------------------------------------------------------------------------

end
