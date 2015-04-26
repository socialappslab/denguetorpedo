# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Reports", :type => :feature do
  let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)       { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:elimination_type) { BreedingSite.first }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }
  let(:base64_image)     { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:inspection_time)  { Time.parse("2015-01-01 10:00") }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)

    I18n.default_locale = User::Locales::SPANISH
  end

  #-----------------------------------------------------------------------------

  describe "Visiting Reports page" do
    before(:each) do
      sign_in(user)

      6.times do |index|
        u = (index % 2 == 0 ? user : other_user)
        r = FactoryGirl.build(:report, :report => "Report with index #{index}", :reporter_id => u.id, :created_at => inspection_time, :completed_at => inspection_time)
        if index == 0
          r.elimination_method_id = r.breeding_site.elimination_methods.first.id
          r.eliminated_at = inspection_time + 5.minutes
          r.after_photo = Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
        end

        r.save!
      end

      visit neighborhood_reports_path(user.neighborhood)
    end

    it "displays the description text" do
      expect(page).to have_content("Esta página muestra reportes de criaderos potenciales o positivos en la comunidad")
    end

    it "displays Call-To-Action button for un-eliminated reports" do
      expect( page.all(".eliminate-report-button").length ).to eq(5)
    end

    it "displays open reports first (ordered by last updated)" do
      first_report = page.all(".report")[0]
      last_report  = page.all(".report")[-1]

      expect(first_report).to have_content("Report with index 5")
      expect(last_report).to have_content("Report with index 0")
    end
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
        expect(report.neighborhood_id).to eq(Neighborhood.first.id)

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

  #-----------------------------------------------------------------------------
  describe "Eliminating a report" do
    let!(:report) { FactoryGirl.create(:report,
      :location_id => location.id,
      :completed_at => Time.now,
      :reporter_id => user.id) }

    before(:each) do
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
      page.find(".compressed_photo", :visible => false).set(base64_image)
      page.find(".submit-button").click

      expect(page).to have_content("Eliminado")
      expect(page).to have_content(report.reporter.display_name)
      expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq(Time.now.strftime("%Y-%m-%d"))
    end

    it "does not overwrite the reporter id when a different user eliminates report" do
      sign_out(user)
      sign_in(other_user)
      visit edit_neighborhood_report_path(user.neighborhood, report)

      select(elimination_type.elimination_methods.first.description, :from => "report_elimination_method_id")
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

      page.find(".compressed_photo", :visible => false).set(base64_image)
      page.find(".submit-button").click

      expect(report.reload.eliminator_id).to eq(other_user.id)
      expect(report.reload.eliminator_id).not_to eq(user.id)
    end

    it "notifies user if elimination method isn't selected" do
      page.find(".compressed_photo", :visible => false).set(base64_image)
      page.find(".submit-button").click

      expect(page).to have_content("Método de eliminación es obligatorio")
    end

    it "notifies user if after photo isn't selected" do
      method = elimination_type.elimination_methods.first
      select(method.description, :from => "report_elimination_method_id")
      page.find(".submit-button").click

      expect(page).to have_content("Foto de eliminación es obligatorio")
    end
  end

  #-----------------------------------------------------------------------------

  context "Creating a report through SMS" do
    # The following definitions is how a report is created through SMS in
    # gateway action of ReportsController.
    let(:sms_body) { "This is an SMS message" }

    before(:each) do
      sign_in(user)

      @report = user.build_report_via_sms(:body => sms_body)
      @report.save!
    end

    it "displays a banner notifying user has an incomplete report" do
      visit neighborhood_reports_path(user.neighborhood)
      expect(page).to have_content("Usted tiene un reporte incompleto")
    end

    it "hides SMS report from the public" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(user.neighborhood)
      expect(page).not_to have_content(sms_body)
    end

    it "notifies the user if report before photo is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      fill_in "report_report", :with => "This is a description"
      select(elimination_type.description, :from => "report_breeding_site_id")
      page.find(".submit-button").click

      expect(page).to have_content("Foto de eliminación es obligatorio")
    end

    it "notifies the user if identification type is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)
      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      fill_in "report_report", :with => "This is a description"
      page.find(".compressed_photo", :visible => false).set(base64_image)
      page.find(".submit-button").click
      expect(page).to have_content("Tipo de criadero es obligatorio")
    end

    it "appears in the reports list as completed" do
      pending "Select does not work for some reason"

      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_address", :with => "Rua Boca 500"
      fill_in "report_report", :with => "This is a description"
      page.find(".compressed_photo", :visible => false).set(base64_image)
      select(elimination_type.description, :from => "report_breeding_site_id")
      page.find(".submit-button").click

      expect(page).to have_content("Foco marcado com sucesso")

      visit neighborhood_reports_path(user.neighborhood)

      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")
      find('#report_elimination_method_id').find(:xpath, 'option[2]').select_option
      page.find(".compressed_photo", :visible => false).set(base64_image)
      page.find(".submit-button").click

      expect(page).to have_content("Você eliminou o foco")
      expect(page).to have_content("Eliminado")
      expect(page).to have_content(@report.reporter.first_name)
    end
  end

  #---------------------------------------------------------------------------

end
