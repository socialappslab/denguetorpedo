# -*- encoding : utf-8 -*-
require "rails_helper"

describe "CSV", :type => :feature do
  let(:user) 		 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:location) { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)     { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let!(:csv)     { FactoryGirl.create(:csv_report, :location => location, :parsed_at => Time.zone.now, :csv => File.open(Rails.root + "spec/support/nicaragua_csv/N002001003.xlsx"), :user_id => user.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    I18n.locale = User::Locales::SPANISH
    sign_in(user)

    report = FactoryGirl.build(:report, :csv_report_id => csv.id)
    report.save(:validate => false)

    visit verify_csv_report_path(csv)
  end

  it "displays descriptive message about verification" do
    expect(page).to have_content("NOTE: To verify a CSV, verify all")
  end

  it "displays Needs Verification in CsvReports#index view" do
    visit csv_reports_path
    expect(page.all("tr")[0]).to have_content("Needs verification")
  end

  it "displays N reports associated with report" do
    expect(page.all("tr").count).to eq(csv.reports.count)
  end

  it "Clicking Delete CSV deletes the CSV" do
    expect {
      click_button "Delete CSV"
    }.to change(CsvReport, :count).by(-1)
  end

  it "should not display Verify CSV button" do
    expect(page).not_to have_css("Verify CSV")
  end

  it "clicking on Verify for each report takes to report's verification page" do
    click_link "Verify"
    first_report = csv.reports.first
    expect(current_path).to eq( verify_neighborhood_report_path(first_report.neighborhood, first_report) )
  end

  it "displays Verified for verified report" do
    first_report = csv.reports.first
    first_report.update_column(:verified_at, Time.zone.now)
    visit verify_csv_report_path(csv)
    expect(page.all("tr")[0]).to have_content("Verified")
  end

  #----------------------------------------------------------------------------

  describe "Verifying all reports" do
    before(:each) do
      csv.reports.each do |r|
        r.update_column(:verified_at, Time.zone.now)
      end

      visit verify_csv_report_path(csv)
    end

    it "displays success message" do
      expect(page).to have_content("You've verified all reports in the CSV. Finish by verifying CSV.")
    end
  end

  #----------------------------------------------------------------------------

end
