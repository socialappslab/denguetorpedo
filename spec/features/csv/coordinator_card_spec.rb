# -*- encoding : utf-8 -*-
require "rails_helper"

describe "CSV", :type => :feature do
  let(:user) 		    { create(:user) }
  let(:user2)       { create(:user) }
  let(:coordinator) { create(:coordinator) }
  let(:location)    { create(:location) }
  let!(:csv)        { create(:spreadsheet, :location => location, :parsed_at => Time.zone.now, :csv => File.open(Rails.root + "spec/support/nicaragua_csv/N002001003.xlsx"), :user_id => user.id) }

  before(:each) do
    sign_in(coordinator)
  end

  it "doesn't display matching CSV if user has no CSVs" do
    visit csv_reports_path(:user_id => user2.id)
    expect(page).not_to have_content(location.address)
  end

  it "displays CSV if user has CSVs" do
    visit csv_reports_path(:user_id => user.id)
    expect(page).to have_content(location.address)
  end

end
