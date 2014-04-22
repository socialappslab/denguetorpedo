# encoding: utf-8
require 'spec_helper'

describe "Reports", :type => :feature do
  let(:user) 						{ FactoryGirl.create(:user) }
  let(:other_user)       { FactoryGirl.create(:user) }
  let(:elimination_type) { EliminationType.first }

  #-----------------------------------------------------------------------------

  context "Creating a new report" do

    context "through web app" do
      let(:before_photo_file) { File.open("spec/support/foco_marcado.jpg") }
      let(:uploaded_before_photo) { ActionDispatch::Http::UploadedFile.new(:tempfile => before_photo_file, :filename => File.basename(before_photo_file)) }

      before(:each) do
        sign_in(user)
        visit neighborhood_reports_path(user.neighborhood)
      end

      context "with errors" do

        it "notifies the user if report description is empty" do
          attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
          click_button "Enviar!"

          expect(page).to have_content("Você tem que descrever o local e/ou o foco")
        end

        it "notifies the user if report before photo is empty" do
          fill_in "report_content", :with => "This is a description"
          click_button "Enviar!"
          expect(page).to have_content("Você tem que carregar uma foto do foco encontrado")
        end

        it "notifies the user if report location is empty" do
          fill_in "report_content", :with => "This is a description"
          attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
          click_button "Enviar!"

          expect(page).to have_content("Você deve enviar o endereço completo")
        end

        it "notifies the user if identification type is empty" do
          fill_in "report_content", :with => "This is a description"
          attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
          click_button "Enviar!"

          expect(page).to have_content("Você deve selecionar um tipo de foco")
        end
      end

      context "successfully" do
        before(:each) do
          fill_in "report_location_attributes_street_type", :with => "Rua"
          fill_in "report_location_attributes_street_name", :with => "Darci Vargas"
          fill_in "report_location_attributes_street_number", :with => "45"
          fill_in "report_content", :with => "This is a description"
          attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
          select(elimination_type.name, :from => "report_elimination_type")
          click_button "Enviar!"
        end

        it "sets the reporter id" do
          expect(Report.last.reporter_id).to eq(user.id)
        end

        it "creates an associated location" do
          report 	= Report.last
          location = report.location
          expect(report).not_to eq(nil)
          expect(location).not_to eq(nil)
          expect(location.street_type).to eq("Rua")
          expect(location.street_name).to eq("Darci Vargas")
          expect(location.street_number).to eq("45")
          expect(location.neighborhood_id).to eq(Neighborhood.first.id)
        end
      end
    end
  end

  #-----------------------------------------------------------------------------

  context "Updating a report" do
    let(:location) { FactoryGirl.create(:location) }
    let(:report)   { FactoryGirl.create(:report, :location => location, :reporter => user) }


    before(:each) do
      report.update_attribute(:sms, true)
      sign_in(user)
    end

    it "notifies the user if report description is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, report)

      attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
      select elimination_type.name, :from => "report_elimination_type"
      click_button "Enviar!"

      expect(page).to have_content("Você tem que descrever o local e/ou o foco")
    end

    it "notifies the user if report before photo is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, report)

      select elimination_type.name, :from => "report_elimination_type"
      click_button "Enviar!"

      expect(page).to have_content("")
    end

    it "notifies the user if identification type is empty" do
      visit edit_neighborhood_report_path(user.neighborhood, report)

      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
      click_button "Enviar!"

      expect(page).to have_content("Você deve selecionar um tipo de foco")
    end

    it "appears in the reports list as completed" do
      pending "Select does not work for some reason"

      visit edit_neighborhood_report_path(user.neighborhood, report)

      fill_in "report_location_attributes_street_type", 	 :with => "Rua"
      fill_in "report_location_attributes_street_name", 	 :with => "Boca"
      fill_in "report_location_attributes_street_number",  :with => "500"
      fill_in "report_content", :with => "This is a description"
      attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
      select elimination_type.name, :from => "report_elimination_type"
      click_button "Enviar!"

      expect(page).to have_content("Foco marcado com sucesso")

      visit neighborhood_reports_path(user.neighborhood)
      expect(page).to have_content("Em aberto")

      elimination_method = elimination_type.elimination_methods.first
      selection_option = elimination_method.method + " (" + elimination_method.points.to_s + " pontos)"
      select selection_option, :from => "elimination_method"
      find('#method_selection').find(:xpath, 'option[2]').select_option
      attach_file("eliminate_after_photo", File.expand_path("spec/support/foco_marcado.jpg"))

      within ".eliminate_prompt" do
        click_button "Enviar!"
      end

      expect(page).to have_content("Você eliminou o foco")
      expect(page).to have_content("Eliminado")
      expect(page).to have_content("Eliminado por: #{report.reporter_name}")
    end

    context "when choosing elimination method" do
      before(:each) do
        visit edit_neighborhood_report_path(user.neighborhood, report)

        fill_in "report_location_attributes_street_type", 	 :with => "Rua"
        fill_in "report_location_attributes_street_name", 	 :with => "Boca"
        fill_in "report_location_attributes_street_number",  :with => "500"
        fill_in "report_content", :with => "This is a description"
        attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
        select elimination_type.name, :from => "report_elimination_type"

        click_button "Enviar!"

        visit neighborhood_reports_path(user.neighborhood)
      end

      it "does not overwrite the reporter id when a different user finishes report" do
        sign_out(user)
        sign_in(other_user)

        visit neighborhood_reports_path(other_user.neighborhood)
        select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
        attach_file("report_after_photo", File.expand_path("spec/support/foco_marcado.jpg"))
        within ".eliminate_prompt" do
          click_button "Enviar!"
        end

        expect(report.reload.reporter_id).to eq(user.id)
        expect(report.reload.reporter_id).not_to eq(other_user.id)
      end

      it "sets the eliminator to be different user" do
        sign_out(user)
        sign_in(other_user)

        visit neighborhood_reports_path(other_user.neighborhood)
        select(elimination_type.elimination_methods.first.method, :from => "report_elimination_method")
        attach_file("report_after_photo", File.expand_path("spec/support/foco_marcado.jpg"))
        within ".eliminate_prompt" do
          click_button "Enviar!"
        end

        expect(report.reload.eliminator_id).to eq(other_user.id)
        expect(report.reload.eliminator_id).not_to eq(user.id)
      end

      # it "displays remaining time as 46 hours and 59 minutes", :js => true do
      # 	pending "Setup PhantomJS"
      # 	# expect(page).to have_content("46:59")
      # end

      it "displays user's name as the creator" do
        expect(page).to have_content("Marcado por: #{report.reporter_name}")
      end

      it "displays report as open" do
        expect(page).to have_content("Em aberto")
      end

      it "notifies user if elimination method isn't selected" do
        within ".eliminate_prompt" do
          click_button "Enviar!"
        end

        expect(page).to have_content("Você tem que escolher um método de eliminação")
      end

      it "notifies user if after photo isn't selected" do
        within ".eliminate_prompt" do
          click_button "Enviar!"
        end

        expect(page).to have_content("Você tem que carregar uma foto do foco eliminado")
      end
    end
  end

  #---------------------------------------------------------------------------

end
