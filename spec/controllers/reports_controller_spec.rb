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
	let(:location) {FactoryGirl.create(:location, :address => "Test address") }
	let(:base64_image) { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
	let(:before_photo)     { Report.base64_image_to_paperclip(base64_image) }


	before(:each) do
		request.env["HTTP_REFERER"] = neighborhood_reports_path(Neighborhood.first)

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

			it "creates an inspection visit", :after_commit => true do
				expect(Visit.count).to eq(0)

				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:reporter_id => user.id,
					:compressed_photo => base64_image,
					:location_attributes => location_hash,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}

				expect(Visit.count).to eq(1)
				expect(Visit.last.visit_type).to eq(Visit::Types::INSPECTION)
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
					:breeding_site_id => elimination_type.id
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

			it "creates only one location" do
				expect {
					post :create, :neighborhood_id => Neighborhood.first.id, :report => {
						:report => "This is a description",
						:location_attributes => location_hash,
						:reporter_id => user.id,
						:before_photo => uploaded_photo,
						:breeding_site_id => elimination_type.id,
						:neighborhood_id => Neighborhood.first.id
					}
				}.to change(Location, :count).by(1)
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

	#---------------------------------------------------------------------------

	context "when eliminating reports" do
		let(:report) {FactoryGirl.create(:report, :completed_at => Time.now, :location_id => location.id, :before_photo => before_photo, :reporter_id => user.id, :report => "This is a description",:breeding_site_id => elimination_type.id, :neighborhood_id => Neighborhood.first.id) }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "correctly sets the eliminated_at" do
			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:compressed_photo => base64_image,
				:elimination_method_id => BreedingSite.first.elimination_methods.first.id,
				:eliminated_at => "2015-12-25 15:00"
			}

			r = Report.last
			expect(r.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-12-25")
			expect(r.eliminated_at.strftime("%H:%M")).to eq("15:00")
		end

		it "creates a follow-up visit", :after_commit => true do
			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:compressed_photo => base64_image,
				:elimination_method_id => BreedingSite.first.elimination_methods.first.id,
				:eliminated_at => "2015-12-25 15:00"
			}

			expect(Visit.last.visit_type).to eq(Visit::Types::FOLLOWUP)
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
			expect(location.reload.neighborhood_id).to eq(Neighborhood.first.id)
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
