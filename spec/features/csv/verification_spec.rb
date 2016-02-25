# -*- encoding : utf-8 -*-
require "rails_helper"

describe "CSV", :type => :feature do
  let(:user) 		 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:location) { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)     { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let!(:csv)     { FactoryGirl.create(:spreadsheet, :location => location, :parsed_at => Time.zone.now, :csv => File.open(Rails.root + "spec/support/nicaragua_csv/N002001003.xlsx"), :user_id => user.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    I18n.locale = User::Locales::SPANISH
    sign_in(user)

    report = FactoryGirl.build(:report, :verified_at => nil, :csv_id => csv.id)
    report.save(:validate => false)

    visit verify_csv_report_path(csv)
  end

  it "should not display Verify CSV button" do
    expect(page).not_to have_css( I18n.t("views.csv_reports.verify") )
  end

  #----------------------------------------------------------------------------

end
