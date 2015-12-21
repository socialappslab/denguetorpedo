# -*- encoding : utf-8 -*-
require "rails_helper"

describe "CSV", :type => :feature do
  let(:user) 		 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:location) { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)     { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let!(:csv)     { Rails.root + "spec/support/csv/inspection_date_in_future.xlsx" }
  let(:default_params) { {:report_location_attributes_latitude => 12.1308585524794, :report_location_attributes_longitude => -86.28059864131501, :neighborhood_id => Neighborhood.first.id} }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    I18n.locale = User::Locales::SPANISH
    sign_in(user)
    Sidekiq::Testing.inline!
  end

  after(:each) do
    Sidekiq::Testing.fake!
  end

  it "displays unknown format error" do
    csv = FactoryGirl.create(:csv_report, :csv => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :user_id => user.id, :location => location)
    CsvParsingWorker.perform_async(csv.id)

    visit csv_report_path(CsvReport.last)
    expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::UNKNOWN_FORMAT] )
  end

  it "displays unknown code error" do
    csv = File.open("spec/support/csv/unknown_code.xlsx")
    csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)
    CsvParsingWorker.perform_async(csv.id)

    visit csv_report_path(CsvReport.last)
    expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::UNKNOWN_CODE] )
  end

  it "displays inspection date in future error" do
    csv = File.open("spec/support/csv/inspection_date_in_future.xlsx")
    csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)
    CsvParsingWorker.perform_async(csv.id)

    visit csv_report_path(CsvReport.last)
    expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::VISIT_DATE_IN_FUTURE] )
  end

  it "displays elimination date in future error" do
    csv = File.open("spec/support/csv/elimination_date_in_future.xlsx")
    csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)
    CsvParsingWorker.perform_async(csv.id)

    visit csv_report_path(csv)
    expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::ELIMINATION_DATE_IN_FUTURE] )
  end

  it "displays elimination date before inspection date error" do
    csv = File.open("spec/support/csv/elimination_date_before_inspection_date.xlsx")
    csv = FactoryGirl.create(:csv_report, :csv => csv, :user_id => user.id, :location => location)
    CsvParsingWorker.perform_async(csv.id)

    visit csv_report_path(CsvReport.last)
    expect(page).to have_content( CsvError.humanized_errors[CsvError::Types::ELIMINATION_DATE_BEFORE_VISIT_DATE] )
  end

  #---------------------------------------------------------------------------

end
