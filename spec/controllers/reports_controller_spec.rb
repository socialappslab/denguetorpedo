# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ReportsController do
	let!(:neighborhood)    { FactoryGirl.create(:neighborhood) }
	let(:user) 						 { FactoryGirl.create(:user) }
	let(:other_user) 			 { FactoryGirl.create(:user) }
	let(:elimination_type) { FactoryGirl.create(:breeding_site) }
	let(:location_hash) 	 {
		{
			:street_type => "Rua", :street_name => "Darci Vargas",
			:street_number => "45", :latitude => "50.0", :longitude => "40.0"
		}
	}
	let(:location) 					{ FactoryGirl.create(:location, :address => "Test address") }
	let(:base64_image) 			{ "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}

	before(:each) do
		request.env["HTTP_REFERER"] = neighborhood_reports_path(Neighborhood.first)

		team = FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id)
		FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
		FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)
	end

	#-----------------------------------------------------------------------------

	context "when creating a report" do
		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "creates a report if no map coordinates are present" do
			location_hash.delete(:latitude)
			location_hash.delete(:longitude)

			expect {
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:reporter_id => user.id,
					:compressed_photo => base64_image,
					:location_attributes => location_hash,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}
			}.to change(Report, :count).by(1)
		end

		it "saves the 'address' attribute of Location" do
			post :create, :neighborhood_id => Neighborhood.first.id, :report => {
				:report => "This is a description",
				:reporter_id => user.id,
				:compressed_photo => base64_image,
				:location_attributes => location_hash,
				:breeding_site_id => elimination_type.id,
				:neighborhood_id => Neighborhood.first.id,
				:location_attributes => {
					:address => "The Barrio"
				}
			}

			l = Location.last
			expect(l.address).to eq("The Barrio")
		end

		it "creates only one location" do
			expect {
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description",
					:location_attributes => location_hash,
					:reporter_id => user.id,
					:compressed_photo => base64_image,
					:breeding_site_id => elimination_type.id,
					:neighborhood_id => Neighborhood.first.id
				}
			}.to change(Location, :count).by(1)
		end

		describe "with proper attributes" do
			before(:each) do
				post :create, :neighborhood_id => Neighborhood.first.id, :report => {
					:report => "This is a description", :reporter_id => user.id,
					:compressed_photo => base64_image, :location_attributes => location_hash,
					:breeding_site_id => elimination_type.id, :neighborhood_id => Neighborhood.first.id
				}
			end

			it "awards submission points" do
				expect(user.reload.total_points).to eq(User::Points::REPORT_SUBMITTED)
			end

			it "creates an inspection visit", :after_commit => true do
				expect(Visit.count).to eq(1)
				expect(Visit.last.visit_type).to eq(Visit::Types::INSPECTION)
			end

			it "sets neighborhood on the location" do
				expect(Report.last.location.neighborhood_id).to eq(Neighborhood.first.id)
			end

			it "saves the location attributes" do
				report 	= Report.last
				location = report.location
				expect(location.street_type).to eq("Rua")
				expect(location.street_name).to eq("Darci Vargas")
				expect(location.street_number).to eq("45")
			end


			it "adds latitude/longitude to location robject if found" do
				expect(Report.last.location.latitude).to  eq(50.0)
				expect(Report.last.location.longitude).to eq(40.0)
	    end
		end


	end

	#---------------------------------------------------------------------------

	context "when preparing a report" do
		let(:location)   { FactoryGirl.create(:location) }
		let(:csv_report) { FactoryGirl.create(:csv_report) }
		let(:report)     { FactoryGirl.create(:report, :location => location, :reporter => user, :csv_report_id => csv_report.id) }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "sets report's completed_at attribute" do
			expect(report.completed_at).to eq(nil)
			put :prepare, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:compressed_photo => base64_image,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}
			expect(report.reload.completed_at).not_to eq(nil)
		end

		it "does not require location coordinates" do
			location_hash.delete(:latitude)
			location_hash.delete(:longitude)

			put :prepare, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:compressed_photo => base64_image,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}

			expect(report.reload.incomplete?).to eq(false)
		end

		it "saves the location attributes" do
			put :prepare, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:compressed_photo => base64_image,
				:elimination_method_id => elimination_type.elimination_methods.first.id
			}

			location = report.location.reload
			expect(location.reload.street_type).to eq("Rua")
			expect(location.reload.street_name).to eq("Darci Vargas")
			expect(location.reload.street_number).to eq("45")
			expect(location.reload.neighborhood_id).to eq(Neighborhood.first.id)
			expect(location.reload.latitude).to  eq(50.0)
			expect(location.longitude).to eq(40.0)
		end
	end

	#-----------------------------------------------------------------------------

 	context "when eliminating a report" do
		let(:location) { FactoryGirl.create(:location) }
		let(:inspection_time) { Time.parse("2015-01-01 12:00") }
		let(:report) 	 { FactoryGirl.create(:report, :created_at => inspection_time, :completed_at => inspection_time, :location_id => location.id, :reporter_id => user.id) }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "sets report's eliminated_at attribute to today's date" do
			Time.zone = Neighborhood.first.city.time_zone

			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:compressed_photo => base64_image,
				:elimination_method_id => BreedingSite.first.elimination_methods.first.id
			}

			expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq(Time.now.strftime("%Y-%m-%d"))
		end

		it "sets report's eliminated_at attribute to correct time zone" do
			Time.zone = Neighborhood.first.city.time_zone

			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:compressed_photo => base64_image,
				:elimination_method_id => BreedingSite.first.elimination_methods.first.id,
				:eliminated_at => "2015-02-27 15:00"
			}

			expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-02-27")
			expect(report.eliminated_at.strftime("%H:%M")).to eq("15:00")
		end

		it "creates a follow-up visit", :after_commit => true do
			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:compressed_photo => base64_image,
				:elimination_method_id => BreedingSite.first.elimination_methods.first.id,
				:eliminated_at => "2015-02-27 15:00"
			}

			expect(Visit.order("visited_at ASC").last.visit_type).to eq(Visit::Types::FOLLOWUP)
		end

		it "awards the eliminating user" do
			before_points = other_user.total_points
			method 			  = elimination_type.elimination_methods.first

			post :eliminate, :neighborhood_id => Neighborhood.first.id, :id => report.id, :report => {
				:location_attributes => location_hash,
				:compressed_photo => base64_image,
				:elimination_method_id => method.id
			}

			expect(user.reload.total_points).to eq(before_points + method.points)
		end
	end

	#---------------------------------------------------------------------------

	context "when verifying a Report" do
		let(:admin)  { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id)}
		let(:report) { FactoryGirl.create(:report, :reporter => user) }

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

	context "when liking a Report" do
		let(:report) { FactoryGirl.create(:report, :reporter => user) }

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
