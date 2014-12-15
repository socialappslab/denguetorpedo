# encoding: utf-8
require 'spec_helper'

describe "Reports", :type => :feature do
  let(:user) 						{ FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)       { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:elimination_type) { BreedingSite.first }
  let(:photo_filepath)   { File.expand_path("spec/support/foco_marcado.jpg") }
  let(:photo_file) 			{ File.open("spec/support/foco_marcado.jpg") }
  let(:uploaded_photo)   { ActionDispatch::Http::UploadedFile.new(:tempfile => photo_file, :filename => File.basename(photo_file)) }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)

    I18n.default_locale = User::Locales::SPANISH
  end

  #-----------------------------------------------------------------------------

  context "when creating a report through the web app" do
    before(:each) do
      sign_in(user)
      visit neighborhood_reports_path(user.neighborhood)
      click_link I18n.t("common_terms.create_a_report")
    end

    it "notifies the user if report description is empty" do
      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      attach_file("report_before_photo", photo_filepath)

      select(elimination_type.description, :from => "report_breeding_site_id")
      click_button I18n.t("views.buttons.create")
      expect(page).to have_content("Descripción es obligatorio")
    end

    it "notifies the user if report before photo is empty" do
      fill_in "report_content", :with => "This is a description"
      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      select(elimination_type.description, :from => "report_breeding_site_id")
      click_button I18n.t("views.buttons.create")
      expect(page).to have_content("Foto del criadero es obligatorio")
    end

    it "notifies the user if identification type is empty" do
      fill_in "report_content", :with => "This is a description"
      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      attach_file("report_before_photo", photo_filepath)
      click_button I18n.t("views.buttons.create")
      expect(page).to have_content("Tipo de criadero es obligatorio")
    end

    context "successfully" do
      before(:each) do
        fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
        fill_in "report_content", :with => "This is a description"
        attach_file("report_before_photo", photo_filepath)
        select(elimination_type.description, :from => "report_breeding_site_id")
        click_button I18n.t("views.buttons.create")
      end

      it "sets the before photo" do
        expect(photo_filepath).to include(Report.last.before_photo_file_name)
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
        # expect(location.street_type).to eq("Rua")
        # expect(location.street_name).to eq("Darci Vargas")
        # expect(location.street_number).to eq("45")
        expect(location.address).to eq("Rua Darci Vargas 45")
      end

      it "displays user's name as the creator" do
        expect(page).to have_content(Report.last.reporter.display_name)
      end

      it "displays report as open" do
        expect(page).to have_content("Abierto para")
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
  context "Eliminating a Report" do
    let!(:report) { FactoryGirl.create(:report,
      :location_id => location.id,
      :before_photo => uploaded_photo,
      :report => "Description",
      :completed_at => Time.now,
      :reporter_id => user.id,
      :breeding_site_id => elimination_type.id,
      :neighborhood_id => Neighborhood.first.id) }

    before(:each) do
      sign_in(user)
    end

    it "sets the after photo" do
      visit neighborhood_reports_path(user.neighborhood)
      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")
      attach_file("report_after_photo", photo_filepath)

      click_button( I18n.t("views.buttons.submit") )
      expect( photo_filepath ).to include(report.reload.after_photo_file_name)
    end

    it "allows users to eliminate a report" do
      visit neighborhood_reports_path(user.neighborhood)

      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")
      attach_file("report_after_photo", photo_filepath)
      click_button I18n.t("views.buttons.submit")

      expect(page).to have_content("Eliminado")
      expect(page).to have_content(report.reporter.display_name)
    end

    it "does not overwrite the reporter id when a different user eliminates report" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(other_user.neighborhood)

      select(elimination_type.elimination_methods.first.description, :from => "report_elimination_method_id")
      attach_file("report_after_photo", photo_filepath)
      click_button I18n.t("views.buttons.submit")

      expect(report.reload.reporter_id).to eq(user.id)
      expect(report.reload.reporter_id).not_to eq(other_user.id)
    end

    it "sets the eliminator to be appropriate user" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(other_user.neighborhood)

      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")

      attach_file("report_after_photo", photo_filepath)
      click_button I18n.t("views.buttons.submit")

      expect(report.reload.eliminator_id).to eq(other_user.id)
      expect(report.reload.eliminator_id).not_to eq(user.id)
    end

    it "notifies user if elimination method isn't selected" do
      visit neighborhood_reports_path(other_user.neighborhood)

      attach_file("report_after_photo", photo_filepath)
      click_button I18n.t("views.buttons.submit")

      expect(page).to have_content("Método de eliminación es obligatorio")
    end

    it "notifies user if after photo isn't selected" do
      visit neighborhood_reports_path(other_user.neighborhood)

      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")
      click_button I18n.t("views.buttons.submit")

      expect(page).to have_content("Foto del criadero es obligatorio")
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

    it "displays the SMS report to the owner" do
      visit neighborhood_reports_path(user.neighborhood)

      expect(page).to have_content(sms_body)
      expect(page).to have_content("Complete el marcado del criadero")
      expect(page).to have_content("Torpedo")
    end

    it "hides SMS report from the public" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(user.neighborhood)
      expect(page).not_to have_content(sms_body)
    end

    it "allows owner to finish report" do
      visit neighborhood_reports_path(user.neighborhood)
      click_button( I18n.t("views.buttons.create") )
      expect(current_path).to eq(edit_neighborhood_report_path(user.neighborhood, @report))
    end

    it "notifies the user if report before photo is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      fill_in "report_content", :with => "This is a description"
      select(elimination_type.description, :from => "report_breeding_site_id")
      click_button I18n.t("views.buttons.create")

      expect(page).to have_content("Foto del criadero es obligatorio")
    end

    it "notifies the user if identification type is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_address", :with => "Rua Darci Vargas 45"
      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", photo_filepath)
      click_button I18n.t("views.buttons.create")

      expect(page).to have_content("Tipo de criadero es obligatorio")
    end

    it "appears in the reports list as completed" do
      pending "Select does not work for some reason"

      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_address", :with => "Rua Boca 500"
      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", photo_filepath)
      select(elimination_type.description, :from => "report_breeding_site_id")
      click_button I18n.t("views.buttons.create")

      expect(page).to have_content("Foco marcado com sucesso")

      visit neighborhood_reports_path(user.neighborhood)

      method = elimination_type.elimination_methods.first
      select(method.description + " (#{method.points} #{I18n.t("attributes.points").downcase})", :from => "report_elimination_method_id")
      find('#report_elimination_method_id').find(:xpath, 'option[2]').select_option
      attach_file("eliminate_after_photo", photo_filepath)
      click_button I18n.t("views.buttons.create")

      expect(page).to have_content("Você eliminou o foco")
      expect(page).to have_content("Eliminado")
      expect(page).to have_content(@report.reporter.first_name)
    end
  end

  #---------------------------------------------------------------------------

end
