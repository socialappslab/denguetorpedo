# encoding: utf-8
require 'spec_helper'

describe "Reports", :type => :feature do
  let(:user) 						{ FactoryGirl.create(:user) }
  let(:other_user)       { FactoryGirl.create(:user) }
  let(:elimination_type) { EliminationType.first }
  let(:photo_filepath)   { File.expand_path("spec/support/foco_marcado.jpg") }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => Neighborhood.first) }

  #-----------------------------------------------------------------------------

  context "when creating a report through the web app" do
    before(:each) do
      sign_in(user)
      visit neighborhood_reports_path(user.neighborhood)
    end

    it "notifies the user if report description is empty" do
      fill_in "report_location_attributes_street_type", :with => "Rua"
      fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
      fill_in "report_location_attributes_street_number", :with => "45"
      attach_file("report_before_photo", photo_filepath)
      select(elimination_type.name, :from => "report_elimination_type")
      click_button "Enviar!"
      expect(page).to have_content("Você tem que descrever o local e/ou o foco")
    end

    it "notifies the user if report before photo is empty" do
      fill_in "report_content", :with => "This is a description"
      fill_in "report_location_attributes_street_type", :with => "Rua"
      fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
      fill_in "report_location_attributes_street_number", :with => "45"
      select(elimination_type.name, :from => "report_elimination_type")
      click_button "Enviar!"
      expect(page).to have_content("Você tem que carregar uma foto do foco encontrado")
    end

    it "notifies the user if report location is empty" do
      fill_in "report_content", :with => "This is a description"
      select(elimination_type.name, :from => "report_elimination_type")
      attach_file("report_before_photo", photo_filepath)
      click_button "Enviar!"
      expect(page).to have_content("Você deve enviar o endereço completo")
    end

    it "notifies the user if identification type is empty" do
      fill_in "report_content", :with => "This is a description"
      fill_in "report_location_attributes_street_type", :with => "Rua"
      fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
      fill_in "report_location_attributes_street_number", :with => "45"
      attach_file("report_before_photo", photo_filepath)
      click_button "Enviar!"
      expect(page).to have_content("Você tem que escolher um tipo de foco")
    end

    context "successfully" do
      before(:each) do
        fill_in "report_location_attributes_street_type", :with => "Rua"
        fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
        fill_in "report_location_attributes_street_number", :with => "45"
        fill_in "report_content", :with => "This is a description"
        attach_file("report_before_photo", photo_filepath)
        select(elimination_type.name, :from => "report_elimination_type")
        click_button "Enviar!"
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
        expect(location.street_type).to eq("Rua")
        expect(location.street_name).to eq("Darci Vargas")
        expect(location.street_number).to eq("45")
      end

      it "displays user's name as the creator" do
        expect(page).to have_content("Marcado por: #{Report.last.reporter_name}")
      end

      it "displays report as open" do
        expect(page).to have_content("Em aberto")
      end

      it "appears in the public reports list" do
        sign_out(user)
        sign_in(other_user)

        visit neighborhood_reports_path(other_user.neighborhood)
        expect(page).to have_content(Report.last.report)
      end

      # it "displays remaining time as 46 hours and 59 minutes", :js => true do
      # 	pending "Setup PhantomJS"
      # 	# expect(page).to have_content("46:59")
      # end
    end
  end

  #-----------------------------------------------------------------------------
  context "Eliminating a Report" do
    let!(:report) { FactoryGirl.create(:report,
      :location_id => location.id,
      :status => Report::STATUS[:reported],
      :completed_at => Time.now,
      :reporter_id => user.id,
      :elimination_type => elimination_type.name,
      :neighborhood_id => Neighborhood.first.id) }

    before(:each) do
      sign_in(user)
    end

    it "sets the after photo" do
      visit neighborhood_reports_path(user.neighborhood)



      select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
      attach_file("report_after_photo", photo_filepath)
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect( photo_filepath ).to include(report.reload.after_photo_file_name)
    end

    it "allows users to eliminate a report" do
      visit neighborhood_reports_path(user.neighborhood)

      select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
      attach_file("report_after_photo", photo_filepath)
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(page).to have_content("Eliminado")
      expect(page).to have_content("Eliminado por: #{report.reporter_name}")
    end

    it "does not overwrite the reporter id when a different user eliminates report" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(other_user.neighborhood)

      select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
      attach_file("report_after_photo", photo_filepath)
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(report.reload.reporter_id).to eq(user.id)
      expect(report.reload.reporter_id).not_to eq(other_user.id)
    end

    it "sets the eliminator to be appropriate user" do
      sign_out(user)
      sign_in(other_user)
      visit neighborhood_reports_path(other_user.neighborhood)

      select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
      attach_file("report_after_photo", photo_filepath)
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(report.reload.eliminator_id).to eq(other_user.id)
      expect(report.reload.eliminator_id).not_to eq(user.id)
    end

    it "notifies user if elimination method isn't selected" do
      visit neighborhood_reports_path(other_user.neighborhood)

      attach_file("report_after_photo", photo_filepath)
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(page).to have_content("Você tem que escolher um método de eliminação")
    end

    it "notifies user if after photo isn't selected" do
      visit neighborhood_reports_path(other_user.neighborhood)

      select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(page).to have_content("Você tem que carregar uma foto do foco eliminado")
    end
  end

  #-----------------------------------------------------------------------------

  context "Creating a report through SMS" do
    # The following definitions is how a report is created through SMS in
    # gateway action of ReportsController.
    let(:sms_body) { "This is an SMS message" }
    let(:location) { FactoryGirl.create(:location, :address => sms_body)}

    before(:each) do
      sign_in(user)

      @report = user.build_report_via_sms(:body => sms_body)
      @report.save!
    end

    it "displays the SMS report to the owner" do
      visit neighborhood_reports_path(user.neighborhood)

      expect(page).to have_content(sms_body)
      expect(page).to have_content("Completar o foco")
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
      click_link("Completar o foco")
      expect(current_path).to eq(edit_neighborhood_report_path(user.neighborhood, @report))
    end

    it "notifies the user if report before photo is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_street_type", :with => "Rua"
      fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
      fill_in "report_location_attributes_street_number", :with => "45"
      fill_in "report_content", :with => "This is a description"
      select(elimination_type.name, :from => "report_elimination_type")
      click_button "Enviar!"

      expect(page).to have_content("Você tem que carregar uma foto do foco encontrado")
    end

    it "notifies the user if identification type is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_street_type", :with => "Rua"
      fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
      fill_in "report_location_attributes_street_number", :with => "45"
      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", photo_filepath)
      click_button "Enviar!"

      expect(page).to have_content("Você tem que escolher um tipo de foco")
    end

    it "appears in the reports list as completed" do
      pending "Select does not work for some reason"

      visit edit_neighborhood_report_path(user.neighborhood, @report)

      fill_in "report_location_attributes_street_type", 	 :with => "Rua"
      fill_in "report_location_attributes_street_name", 	 :with => "Boca"
      fill_in "report_location_attributes_street_number",  :with => "500"
      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", photo_filepath)
      select elimination_type.name, :from => "report_elimination_type"
      click_button "Enviar!"

      expect(page).to have_content("Foco marcado com sucesso")

      visit neighborhood_reports_path(user.neighborhood)
      expect(page).to have_content("Em aberto")

      elimination_method = elimination_type.elimination_methods.first
      selection_option = elimination_method.method + " (" + elimination_method.points.to_s + " pontos)"
      select selection_option, :from => "elimination_method"
      find('#method_selection').find(:xpath, 'option[2]').select_option
      attach_file("eliminate_after_photo", photo_filepath)

      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(page).to have_content("Você eliminou o foco")
      expect(page).to have_content("Eliminado")
      expect(page).to have_content("Eliminado por: #{@report.reporter_name}")
    end
  end

  #---------------------------------------------------------------------------

end
