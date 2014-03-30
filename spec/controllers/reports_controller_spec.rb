# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	let(:user) { FactoryGirl.create(:user) }
	#-----------------------------------------------------------------------------

	context "Creating a new report" do
		render_views

		describe "with errors" do
			it "alerts user if description is not present" do
			end
		end

		context "via SMS" do

			it "creates a new report with proper attributes" do
				expect {
					post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				}.to change(Report, :count).by(1)

				report = Report.find_by_report("Rua Tatajuba 1")
				expect(report.status_cd).to eq(0)
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

		end

		context "Updating a report" do
			let(:location) { FactoryGirl.create(:location) }
			let(:report) { FactoryGirl.create(:report, :location => location, :reporter => user) }

			context "when report comes in through SMS" do
				before(:each) do
					report.update_attribute(:sms, true)
					sign_in(user)
				end

				it "notifies the user if report description is empty" do
					visit edit_neighborhood_report_path(user.neighborhood, report)

					fill_in "report_content", :with => ""
					click_button "Enviar!"

					expect(page).to have_content(" LOLLLL")
				end

				it "notifies the user if report before photo is empty" do
					visit edit_neighborhood_report_path(user.neighborhood, report)

					fill_in "report_before_photo", :with => ""
					click_button "Enviar!"

					expect(page).to have_content(" LOLLLL")
				end

				it "notifies the user if report location is empty" do
					visit edit_neighborhood_report_path(user.neighborhood, report)

					fill_in "street_type", :with => ""
					click_button "Enviar!"

					expect(page).to have_content(" LOLLLL")
				end


			end

		end

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
