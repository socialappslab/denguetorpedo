# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	let(:user) { FactoryGirl.create(:user) }
	#-----------------------------------------------------------------------------

	it "returns unread notifications when accessing /reports/notifications" do
		notification = FactoryGirl.create(:notification, :read => false)
		get "notifications"
		expect(JSON.parse(response.body).length).to eq(1)
	end

	context "Creating a new report" do
		render_views

		describe "with errors" do
			it "alerts user if description is not present" do
			end
		end

		context "via SMS" do

      # TODO Change text to be dynamic when additional languages are added

      context "when phone number is not registered" do
        let(:unregistered) {"123456789012"}
        it "should create notification" do
          expect{
            post "gateway", :body => "Rua Tatajuba 1", :from => :unregistered
          }.to change(Notification, :count).by(1)
        end

        it "should respond with correct text" do
          post "gateway", :body => "Rua Tatajuba 1", :from => :unregistered
          expect(Notification.last.text).to eq("Você ainda não tem uma conta. Registre-se no site do Dengue Torpedo.")
        end

      end

      context "when phone number is registered" do
        it "should create a notification" do
          expect{
            post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
          }.to change(Notification, :count).by(1)
        end

        it "should respond with correct text" do
          post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
          expect(Notification.last.text).to eq("Parabéns! O seu relato foi recebido e adicionado ao Dengue Torpedo.")
        end

      end

      context "when the phone number is below minimum" do
        it "should not create a notification" do
          expect{
            post "gateway", :body => "Rua Tatajuba 1", :from => "1"
          }.not_to change(Notification, :count).by(1)
        end
      end

      it "should have the correct date" do
        expect {
          post "gateway", :body => "Testing the date", :from => user.phone_number
        }.to change(Report, :count).by(1)

        report = Report.find_by_report("Testing the date")
        expect(report.created_at.strftime("%d %b. %Y")).to eq(Time.now.strftime("%d %b. %Y"))
      end


			it "creates a new report with proper attributes" do
				expect {
					post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				}.to change(Report, :count).by(1)

				report = Report.find_by_report("Rua Tatajuba 1")
				expect(report.status_cd).to eq(nil)
				expect(report.sms).to eq(true)
			end

			it "creates a new location for the report with proper attributes" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				report = Report.find_by_report("Rua Tatajuba 1")
				expect(report.location).not_to eq(nil)
				expect(report.location.neighborhood_id).to eq(user.neighborhood_id)
			end

			it "displays the report in the reports page" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number

				sign_in(user)

				visit neighborhood_reports_path(user.neighborhood)
				expect(page).to have_content("Completar o foco")
			end

			it "does not display report for other users" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number

				other_user = FactoryGirl.create(:user)
				sign_in(other_user)

				visit neighborhood_reports_path(user.neighborhood)
				expect(page).not_to have_content("Completar o foco")
      end

      context "when on My House (Minha Casa) page" do
				let(:other_user) { FactoryGirl.create(:user) }

        before(:each) do
          post "gateway", :body => "Not in my house!", :from => user.phone_number
        end

        it "should not be displayed for owner" do
          sign_in(user)
          visit neighborhood_house_path({:neighborhood_id => user.neighborhood.id, :id => user.house.id})
          expect(page).not_to have_content("Not in my house!")
        end

        it "should not be displayed for other house members" do
          sign_in(other_user)
          visit neighborhood_house_path({:neighborhood_id => other_user.neighborhood.id, :id => other_user.house.id})
          expect(page).not_to have_content("Not in my house!")
        end

        it "should display after completing" do
          report 						 = Report.find_by_report("Not in my house!")
          report.status 			= :reported
          report.status_cd 	 = 1
          report.completed_at = Time.now
          report.save!

          sign_in(user)
          visit neighborhood_house_path({:neighborhood_id => user.neighborhood.id, :id => user.house.id})

					expect(report.reload.status_cd).to eq(1)
          expect(page).to have_content("Not in my house!")
        end
      end
		end

		#---------------------------------------------------------------------------

		context "Updating a report" do
			let(:location) { FactoryGirl.create(:location) }
			let(:report)   { FactoryGirl.create(:report, :location => location, :reporter => user) }
			let(:elimination_type) { EliminationType.first }

			context "when report comes in through SMS" do
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

					fill_in "street_type", 	 :with => "Rua"
					fill_in "street_name", 	 :with => "Boca"
					fill_in "street_number",  :with => "500"
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

					save_and_open_page

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

						fill_in "street_type", 	 :with => "Rua"
						fill_in "street_name", 	 :with => "Boca"
						fill_in "street_number",  :with => "500"
						fill_in "report_content", :with => "This is a description"
						attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
						select EliminationType.first.name, :from => "report_elimination_type"

						click_button "Enviar!"

						visit neighborhood_reports_path(user.neighborhood)
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

			context "when report comes" do
				before(:each) do
					sign_in(user)
				end

				it "notifies the user if report description is empty" do
					visit neighborhood_reports_path(user.neighborhood)

					attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
					click_button "Enviar!"

					expect(page).to have_content("Você tem que descrever o local e/ou o foco")
				end

				it "notifies the user if report before photo is empty" do
					visit neighborhood_reports_path(user.neighborhood)

					fill_in "report_content", :with => "This is a description"
					click_button "Enviar!"
					expect(page).to have_content("Você tem que carregar uma foto do foco encontrado")
				end

				it "notifies the user if report location is empty" do
					visit neighborhood_reports_path(user.neighborhood)

					fill_in "report_content", :with => "This is a description"
					attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
					click_button "Enviar!"

					expect(page).to have_content("Você deve enviar o endereço completo")
				end

				it "notifies the user if identification type is empty" do
					visit neighborhood_reports_path(user.neighborhood)

					fill_in "report_content", :with => "This is a description"
					attach_file("report_before_photo", File.expand_path("spec/support/foco_marcado.jpg"))
					click_button "Enviar!"

					expect(page).to have_content("Você deve selecionar um tipo de foco")
				end
			end
		end

		#---------------------------------------------------------------------------

		describe "successfully" do
			let(:user)         		 { FactoryGirl.create(:user) }
			let(:street_hash)  		 { {:street_type => "Rua", :street_name => "Darci Vargas", :street_number => "45"} }
			let(:before_photo_file) { File.open("spec/support/foco_marcado.jpg") }
			let(:uploaded_before_photo) { ActionDispatch::Http::UploadedFile.new(:tempfile => before_photo_file, :filename => File.basename(before_photo_file)) }

			before(:each) do
				cookies[:auth_token] = user.auth_token
			end

			it "creates a report if no map coordinates are present" do
			end

			it "automatically sets neighborhood on the location" do
			end


			# it "finds map coordinates even if user didn't submit them" do
			# 	location = Location.find_by_street_type_and_street_number(street_hash[:street_type], street_hash[:street_number])
			# 	expect(location).to  eq(nil)
			#
			# 	post :create, street_hash.merge(:report => { :report => "Testing", :before_photo => uploaded_before_photo })
			#
			# 	location = Location.find_by_street_type_and_street_number(street_hash[:street_type], street_hash[:street_number])
			# 	expect(location.latitude).to  eq(680555.9952487927)
			# 	expect(location.longitude).to eq(7471957.144050697)
			# end
		end
	end

	#-----------------------------------------------------------------------------

end
