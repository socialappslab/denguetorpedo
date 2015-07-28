# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Verifying a Report", :type => :feature do
  let!(:neighborhood)     { FactoryGirl.create(:neighborhood) }
  let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => neighborhood) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => neighborhood.id) }
  let(:base64_image)     { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let!(:csv)     { FactoryGirl.create(:csv_report, :location => location, :parsed_at => Time.zone.now, :csv => File.open(Rails.root + "spec/support/nicaragua_csv/N002001003.xlsx"), :user_id => user.id) }

  let!(:report) { FactoryGirl.create(:report,
    :location_id => location.id,
    :neighborhood_id => neighborhood.id,
    :reporter_id => user.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)

    I18n.default_locale = User::Locales::SPANISH

    csv.reports << report

    sign_in(user)
    visit verify_neighborhood_report_path(user.neighborhood, report)
  end

  it "notifies if photo? is not chosen" do
    click_button "Actualizar"
    expect(page).to have_content("You need to specify if the report has a before photo or not!")
  end

  it "allows to verify with no photo" do
    choose("has_before_photo_0")
    click_button "Actualizar"
    expect(current_path).to eq(verify_csv_report_path(csv))
  end

  it "allows to verify with photo", :js => true do
    choose("has_before_photo_0")
    page.find(".compressed_photo", :visible => false).set(base64_image)
    click_button "Actualizar"
    expect(current_path).to eq(verify_csv_report_path(csv))
  end

  it "decrements Report count when deleting report", :js => true do
    skip "NOT WORKING FOR SOME REASON"
    page.find("#delete-report-link").trigger("click")
  end

  it "allows to change inspection date" do
    select "5", :from => "report_created_at_3i"
    click_button "Actualizar"
    expect(Report.last.created_at.strftime("%d")).to eq("5")
  end

  it "allows to change breeding site" do
    select BreedingSite.last.id, :from => "breeding_site_id"
    click_button "Actualizar"
    expect(report.reload.breeding_site_id).to eq(BreedingSite.last.id)
  end

  it "allows to change description" do
    choose("has_before_photo_0")
    fill_in "report_report", :with => "haha"
    click_button "Actualizar"
    expect(report.reload.report).to eq("haha")
  end

  it "allows to change larvae" do
  end

  #---------------------------------------------------------------------------

end
