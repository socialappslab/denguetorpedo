# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:other_user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:elimination_type)  { BreedingSite.first }
	let(:photo_file) 			 { File.open("spec/support/foco_marcado.jpg") }
	let(:uploaded_photo)    { ActionDispatch::Http::UploadedFile.new(:tempfile => photo_file, :filename => File.basename(photo_file)) }
	let(:location_hash) 		{ {
		:street_type => "Rua", :street_name => "Darci Vargas",
		:street_number => "45", :latitude => "50.0", :longitude => "40.0"}
	}

	before(:each) do
		team = FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id)
		FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
		FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)
	end

	#-----------------------------------------------------------------------------

	it "returns unread notifications when accessing /reports/notifications" do
		notification = FactoryGirl.create(:notification, :read => false)
		get "notifications"
		expect(JSON.parse(response.body).length).to eq(1)
	end

	#-----------------------------------------------------------------------------

	context "Creating a new report" do
		context "through SMS" do
			render_views

			it "displays the report in the reports page" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				sign_in(user)
				visit neighborhood_reports_path(user.neighborhood)
				expect(page).to have_content("Completar o foco")
			end

			it "does not award points" do
				before_points = user.total_points
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				expect(user.reload.total_points).to eq(before_points)
			end

			it "does not display report for other users" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				sign_in(other_user)

				visit neighborhood_reports_path(user.neighborhood)
				expect(page).not_to have_content("Completar o foco")
			end

			it "should not be displayed for other house members" do
				post "gateway", :body => "Not in my house!", :from => user.phone_number

				sign_in(other_user)
				visit user_path(user)
				expect(page).not_to have_content("Encontrei um foco")
			end


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
        expect(report.created_at.strftime("%b. %Y")).to eq(Time.now.strftime("%b. %Y"))
      end


			it "creates a new report with proper attributes" do
				expect {
					post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				}.to change(Report, :count).by(1)

				report = Report.find_by_report("Rua Tatajuba 1")
				# expect(report.status).to eq(Report::STATUS[:sms])
				expect(report.neighborhood_id).to eq(user.neighborhood_id)
				expect(report.sms).to eq(true)
			end

			it "creates a new location for the report with proper attributes" do
				post "gateway", :body => "Rua Tatajuba 1", :from => user.phone_number
				report = Report.find_by_report("Rua Tatajuba 1")
				expect(report.location).not_to eq(nil)
				expect(report.location.neighborhood_id).to eq(user.neighborhood_id)
			end
		end

		#---------------------------------------------------------------------------

		context "through web app" do
			before(:each) do
				cookies[:auth_token] = user.auth_token
			end


			context "when in Managua" do
				let(:city) { City.find_by_name("Managua") }
				let(:neighborhood) { Neighborhood.find_by_city_id(city.id) }

				it "saves the 'neighborhood' attribute of Location" do
					post :create, :neighborhood_id => neighborhood.id, :report => {
						:report => "This is a description",
						:reporter_id => user.id,
						:before_photo => uploaded_photo,
						:location_attributes => location_hash,
						:breeding_site_id => elimination_type.id,
						:neighborhood_id => neighborhood.id,
						:location_attributes => {
							:neighborhood => "The Barrio"
						}
					}

					l = Location.last
					expect(l.neighborhood).to eq("The Barrio")
				end


			end


			it "awards submission points" do
				before_points = user.total_points
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:reporter_id => user.id,
					:before_photo => uploaded_photo,
					:location_attributes => location_hash,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}
				expect(user.reload.total_points).to eq(before_points + User::Points::REPORT_SUBMITTED)
			end

			it "creates a report if no map coordinates are present" do
				location_hash.delete(:latitude)
				location_hash.delete(:longitude)

				expect {
					post :create, :neighborhood_id => Neighborhood.first.id, :report => {
						:report => "This is a description",
						:reporter_id => user.id,
						:before_photo => uploaded_photo,
						:location_attributes => location_hash,
						:breeding_site_id => elimination_type.id,
						:neighborhood_id => Neighborhood.first.id
					}
				}.to change(Report, :count).by(1)
			end

			it "sets neighborhood on the location" do
				post :create, :neighborhood_id => Neighborhood.first, :report => {
					:report => "This is a description",
					:reporter_id => user.id,
					:before_photo => uploaded_photo,
					:location_attributes => location_hash,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}

				expect(Report.last.location.neighborhood_id).to eq(Neighborhood.first.id)
			end

			it "saves the location attributes" do
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:location_attributes => location_hash,
					:reporter_id => user.id,
					:before_photo => uploaded_photo,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}

				report 	= Report.last
				location = report.location
				expect(location.street_type).to eq("Rua")
				expect(location.street_name).to eq("Darci Vargas")
				expect(location.street_number).to eq("45")
			end

			it "adds latitude/longitude to location robject if found" do
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:reporter_id => user.id,
					:location_attributes => location_hash,
					:before_photo => uploaded_photo,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}

				expect(Report.last.location.latitude).to  eq(50.0)
				expect(Report.last.location.longitude).to eq(40.0)
      end

    end


	end

	#-----------------------------------------------------------------------------

	context "Updating a report" do
		let(:location) { FactoryGirl.create(:location) }
		let(:report)   { FactoryGirl.create(:report, :before_photo => uploaded_photo,
                                        :location => location,
                                        :reporter => user,
																				:neighborhood_id => Neighborhood.first.id,
                                        :breeding_site_id => elimination_type.id,
                                        :report => "Description") }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "does not require coordinates" do
			location_hash.delete(:latitude)
			location_hash.delete(:longitude)

			put :update, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:after_photo => uploaded_photo,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}
		end

		it "saves the location attributes" do
			put :update, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:after_photo => uploaded_photo,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}

			location = report.location.reload
			expect(location.reload.street_type).to eq("Rua")
			expect(location.reload.street_name).to eq("Darci Vargas")
			expect(location.reload.street_number).to eq("45")
		end

		it "adds latitude/longitude to location object if found" do
			put :update, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:after_photo => uploaded_photo,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}

			expect(location.reload.latitude).to  eq(50.0)
			expect(location.reload.longitude).to eq(40.0)
		end

	end

	#-----------------------------------------------------------------------------

	describe "Eliminating a report" do
		let(:location) { FactoryGirl.create(:location) }
		let(:report)   { FactoryGirl.create(:report, :before_photo => uploaded_photo,
																				:location => location,
																				:reporter => user,
																				:neighborhood_id => Neighborhood.first.id,
																				:breeding_site_id => elimination_type.id,
																				:report => "Description") }

		before(:each) do
			cookies[:auth_token] = other_user.auth_token
		end

		it "adds points to eliminator" do
			before_points = other_user.total_points
			method 			 = elimination_type.elimination_methods.first

			put :update, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:after_photo => uploaded_photo,
				:elimination_method_id => method.id
			}

			expect(other_user.reload.total_points).to eq(before_points + method.points)
		end
	end


	#---------------------------------------------------------------------------

	describe "Verifying a Report" do
		let(:admin) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id)}
		let(:report)   { FactoryGirl.create(:report, :before_photo => uploaded_photo,
																				:reporter => user,
																				:neighborhood_id => Neighborhood.first.id,
																				:breeding_site_id => elimination_type.id,
																				:report => "Description") }

		before(:each) do
			cookies[:auth_token] = admin.auth_token
		end

		it "awards points for verifying" do
			before_points = admin.total_points
			post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
			expect(admin.reload.total_points).to eq(before_points + User::Points::REPORT_VERIFIED)
		end

		context "when report is open" do
			it "sets the verified status" do
				expect(report.isVerified).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.isVerified).to eq("t")
			end

			it "sets the verifier id" do
				expect(report.verifier_id).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verifier_id).to eq(admin.id)
			end

			it "sets the verified time" do
				expect(report.verified_at).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verified_at).not_to eq(nil)
			end
		end

		context "when report is eliminated" do
			before(:each) do
				report.update_column(:elimination_method_id, elimination_type.elimination_methods.first.id)
			end

			it "sets the verified status" do
				expect(report.isVerified).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.isVerified).to eq("t")
			end

			it "sets the verifier id" do
				expect(report.verifier_id).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verifier_id).to eq(admin.id)
			end

			it "sets the verified time" do
				expect(report.verified_at).to eq(nil)
				post :verify, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verified_at).not_to eq(nil)
			end
		end

		context "reporting problems with open reports" do
			it "sets the verified status" do
				expect(report.isVerified).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.isVerified).to eq("f")
			end

			it "sets the verifier id" do
				expect(report.verifier_id).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verifier_id).to eq(admin.id)
			end

			it "sets the verified time" do
				expect(report.verified_at).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verified_at).not_to eq(nil)
			end
		end

		context "reporting problems with eliminated reports" do
			before(:each) do
				report.update_column(:elimination_method_id, elimination_type.elimination_methods.first.id)
			end

			it "sets the verified status" do
				expect(report.isVerified).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.isVerified).to eq("f")
			end

			it "sets the verifier id" do
				expect(report.verifier_id).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verifier_id).to eq(admin.id)
			end

			it "sets the verified time" do
				expect(report.verified_at).to eq(nil)
				post :problem, :id => report.id, :neighborhood_id => report.neighborhood_id
				expect(report.reload.verified_at).not_to eq(nil)
			end
		end

	end

	#---------------------------------------------------------------------------

	describe "Liking a Report" do
		let(:report)   { FactoryGirl.create(:report, :before_photo => uploaded_photo,
																				:reporter => user,
																				:neighborhood_id => Neighborhood.first.id,
																				:breeding_site_id => elimination_type.id,
																				:report => "Description") }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "increments number of likes" do
			expect {
				post :like, :id => report.id
			}.to change(Like, :count).by(1)
		end

		it "decrements number of likes" do
			Like.create(:user_id => user.id, :likeable_id => report.id, :likeable_type => Report.name)

			expect {
				post :like, :id => report.id
			}.to change(Like, :count).by(-1)
		end

		it "creates a Like instance with correct attributes" do
			post :like, :id => report.id

			like = Like.first
			expect(like.user_id).to eq(user.id)
			expect(like.likeable_id).to eq(report.id)
			expect(like.likeable_type).to eq(report.class.name)
		end
	end

	#---------------------------------------------------------------------------

end
