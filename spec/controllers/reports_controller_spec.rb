# -*- encoding : utf-8 -*-
require "rails_helper"

describe ReportsController do
	let!(:neighborhood)    { FactoryGirl.create(:neighborhood) }
	let(:user) 						 { FactoryGirl.create(:user) }
	let(:other_user) 			 { FactoryGirl.create(:user) }
	let(:elimination_type) { FactoryGirl.create(:breeding_site) }
	let(:location_hash) 	 {
		{
			:address => "Rua Darci Vargas 45", :latitude => "50.0", :longitude => "40.0"
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
