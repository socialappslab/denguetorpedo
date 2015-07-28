# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Reports", :type => :feature do
  let!(:neighborhood)     { FactoryGirl.create(:neighborhood) }
  let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let(:other_user)       { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let!(:elimination_type) { FactoryGirl.create(:breeding_site) }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => neighborhood) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => neighborhood.id) }
  let(:base64_image)     { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:inspection_time)  { Time.parse("2015-01-01 10:00") }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)

    I18n.default_locale = User::Locales::SPANISH
  end

  #-----------------------------------------------------------------------------

  describe "Creating a report" do
    before(:each) do
      sign_in(user)
      visit new_neighborhood_report_path(user.neighborhood)
    end

    describe "with errors" do

      it "notifies the user if report description is empty" do
        fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
        page.find(".compressed_photo", :visible => false).set(base64_image)

        select(elimination_type.description, :from => "report_breeding_site_id")
        page.find(".submit-button").click
        expect(page).to have_content("Descripción es obligatorio")
      end

      it "notifies the user if report before photo is empty" do
        fill_in "report_report", :with => "This is a description"
        fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
        select(elimination_type.description, :from => "report_breeding_site_id")
        page.find(".submit-button").click
        expect(page).to have_content("Foto del criadero es obligatorio")
      end

      it "notifies the user if identification type is empty" do
        fill_in "report_report", :with => "This is a description"
        fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
        page.find(".compressed_photo", :visible => false).set(base64_image)
        page.find(".submit-button").click
        expect(page).to have_content("Tipo de criadero es obligatorio")
      end
    end

    describe "successfully" do
      before(:each) do
        fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
        fill_in "report_report", :with => "This is a description"
        page.find(".compressed_photo", :visible => false).set(base64_image)
        select(elimination_type.description, :from => "report_breeding_site_id")
        page.find(".submit-button").click
      end

      it "sets the reporter id" do
        expect(Report.last.reporter_id).to eq(user.id)
      end

      it "creates an associated location" do
        report 	= Report.last
        location = report.location

        expect(report).not_to eq(nil)
        expect(report.neighborhood_id).to eq(neighborhood.id)

        expect(location).not_to eq(nil)
        expect(location.address).to eq("Rua Darci Vargas 45")
      end

      it "displays user's name as the creator" do
        expect(page).to have_content(Report.last.reporter.display_name)
      end

      it "appears in the public reports list" do
        sign_out(user)
        sign_in(other_user)

        visit neighborhood_reports_path(other_user.neighborhood)
        expect(page).to have_content(Report.last.report)
      end
    end
  end

  #---------------------------------------------------------------------------

end
