# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Eliminating a Report", :type => :feature do
  let!(:neighborhood)     { FactoryGirl.create(:neighborhood) }
  let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let(:other_user)       { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let!(:elimination_type) { FactoryGirl.create(:breeding_site) }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => neighborhood) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => neighborhood.id) }
  let(:base64_image)     { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:inspection_time)  { Time.parse("2015-01-01 10:00") }
  let!(:report) { FactoryGirl.create(:report,
    :location_id => location.id,
    :created_at => Time.zone.now - 10.days,
    :neighborhood_id => neighborhood.id,
    :completed_at => Time.zone.now,
    :reporter_id => user.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)
    I18n.default_locale = User::Locales::SPANISH

    v = report.find_or_create_first_visit
    report.update_inspection_for_visit(v)

    sign_in(user)
    visit edit_neighborhood_report_path(user.neighborhood, report)
  end

  it "links to a page to eliminate reports" do
    visit neighborhood_reports_path(user.neighborhood)
    expect(page).to have_css(".eliminate-report-button")
  end

  it "allows users to eliminate a report" do
    method = elimination_type.elimination_methods.first
    select(method.description, :from => "report_elimination_method_id")
    choose("has_after_photo_1")
    page.find(".compressed_photo", :visible => false).set(base64_image)
    page.find(".submit-button").click

    expect(page).to have_content("Eliminado")
    expect(page).to have_content(report.reporter.display_name)
  end

  it "does not overwrite the reporter id when a different user eliminates report" do
    sign_out(user)
    sign_in(other_user)
    visit edit_neighborhood_report_path(user.neighborhood, report)

    select(elimination_type.elimination_methods.first.description, :from => "report_elimination_method_id")
    choose("has_after_photo_1")
    page.find(".compressed_photo", :visible => false).set(base64_image)
    page.find(".submit-button").click

    expect(report.reload.reporter_id).to eq(user.id)
    expect(report.reload.reporter_id).not_to eq(other_user.id)
  end

  it "sets the eliminator to be appropriate user" do
    sign_out(user)
    sign_in(other_user)
    visit edit_neighborhood_report_path(user.neighborhood, report)

    method = elimination_type.elimination_methods.first
    select(method.description, :from => "report_elimination_method_id")

    choose("has_after_photo_1")
    page.find(".compressed_photo", :visible => false).set(base64_image)
    page.find(".submit-button").click

    expect(report.reload.eliminator_id).to eq(other_user.id)
    expect(report.reload.eliminator_id).not_to eq(user.id)
  end

  it "notifies user if elimination method isn't selected" do
    visit edit_neighborhood_report_path(user.neighborhood, report.reload)

    choose("has_after_photo_1")
    page.find(".compressed_photo", :visible => false).set(base64_image)
    page.find(".submit-button").click

    expect(page).to have_content("Método de eliminación es obligatorio")
  end

  it "notifies user if after photo isn't selected" do
    choose("has_after_photo_1")
    method = elimination_type.elimination_methods.first
    select(method.description, :from => "report_elimination_method_id")
    page.find(".submit-button").click

    expect(page).to have_content("Foto de eliminación es obligatorio")
  end

end
