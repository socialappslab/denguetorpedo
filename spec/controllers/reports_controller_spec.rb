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

		describe "via web application" do
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
