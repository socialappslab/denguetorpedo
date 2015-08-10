# -*- encoding : utf-8 -*-

require "rails_helper"
require 'rack/test'

describe Report do
	let(:user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:photo_file) { File.open("spec/support/foco_marcado.jpg") }
	let(:location) 	 { FactoryGirl.create(:location, :address => "Test address")}

	before(:each) do
		I18n.locale = "es"
	end

	it "does not require presence of location" do
		expect {
			FactoryGirl.create(:report, :reporter_id => user.id)
		}.to change(Report, :count).by(1)
	end

	it "changes eliminated_at to at least 1 minute if created_at is within threshold" do
		t 		 = Time.zone.now
		r = FactoryGirl.create(:full_report, :created_at => t)

		r.after_photo 					= Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
		r.elimination_method_id = 1
		r.eliminated_at 				= t
		r.save!

		expect(r.eliminated_at).to eq(r.created_at + Report::ELIMINATION_THRESHOLD)
	end

	it "raises an error if elimination date is before creation date" do
		report = FactoryGirl.build(:full_report, :eliminated_at => Time.zone.now - 3.minutes)
		report.save
		expect(report.errors.full_messages).to include("Fecha de eliminación can't be before fecha de inspección")
	end

	it "raises an error if creation date is in the future" do
		report = FactoryGirl.build(:full_report, :created_at => Time.zone.now + 1.minute)
		report.save
		expect(report.errors.full_messages).to include("Fecha de inspección can't be in the future")
	end

	it "raises an error if elimination date is in the future" do
		report = FactoryGirl.build(:full_report, :eliminated_at => Time.zone.now + 3.minutes)
		report.save
		expect(report.errors.full_messages).to include("Fecha de eliminación can't be in the future")
	end

	it "validates on inspection date being after 2014" do
		report = FactoryGirl.build(:full_report, :created_at => Time.parse("0014-10-10"))
		report.save
		expect(report.errors.full_messages).to include("Fecha de inspección can't be before 2014")
	end

	it "returns the correct initial visit" do
		r  = FactoryGirl.create(:full_report, :reporter => user)
		v1 = FactoryGirl.create(:visit, :location_id => location.id, :visited_at => Time.zone.now - 100.days)
		v2 = FactoryGirl.create(:visit, :location_id => location.id, :visited_at => Time.zone.now - 3.days, :parent_visit_id => v1.id)

		FactoryGirl.create(:inspection, :visit_id => v1.id, :report_id => r.id, :identification_type => Inspection::Types::POSITIVE)
		expect(r.initial_visit.id).to eq(v1.id)
	end

	#-----------------------------------------------------------------------------

	describe "Deleting a Report", :after_commit => true do
		before(:each) do
			@report = FactoryGirl.create(:full_report, :report => "Test", :reporter => user, :location => location)
		end

		it "destroys associated inspection" do
			expect {
				@report.destroy
			}.to change(Inspection, :count).by(-1)
		end

		it "destroys associated likes" do
			FactoryGirl.create(:like, :user_id => user.id, :likeable_id => @report.id, :likeable_type => "Report")
			expect {
				@report.destroy
			}.to change(Like, :count).by(-1)
		end

		it "destroys associated comments" do
			FactoryGirl.create(:comment, :content => "Test", :user_id => user.id, :commentable_id => @report.id, :commentable_type => "Report")
			expect {
				@report.destroy
			}.to change(Comment, :count).by(-1)
		end

		it "destroys associated visit if it's the last visit" do
			expect {
				@report.destroy
			}.to change(Visit, :count).by(-1)
		end

		it "does not destroy visit if it's not the last visit" do
			FactoryGirl.create(:full_report, :report => "Test", :reporter => user, :location => location)

			expect {
				@report.destroy
			}.not_to change(Visit, :count)
		end
	end

	#-----------------------------------------------------------------------------

	describe "Exceptions on Validations" do
		it "doesn't validate before photo if save_without_before_photo is set" do
			r  = FactoryGirl.build(:full_report, :report => "Test", :reporter => user, :location => location)
			r.before_photo = nil
			r.verified_at  = nil
			r.save_without_before_photo = true
			r.save
			expect(r.errors.full_messages).to eq([])
		end

		it "doesn't validate after photo or elimination method if completed_at is not set" do
			r  = FactoryGirl.create(:full_report, :report => "Test", :reporter => user, :location => location)
			r.after_photo   = nil
			r.verified_at 	= Time.zone.now
			r.csv_report_id = 1
			r.elimination_method_id		 = r.breeding_site.elimination_methods.first.id
			r.save_without_after_photo = true
			r.save

			expect(r.errors.full_messages).to eq([])
		end
	end

	#-----------------------------------------------------------------------------

	describe "Displayable Scope" do
		it "includes potential but protected sites" do
			r = FactoryGirl.create(:full_report, :larvae => true, :protected => true)
			expect(Report.displayable).to include(r)
		end
	end

	#-----------------------------------------------------------------------------

	describe "Completed Scope" do
		it "includes only completed reports" do
			r = FactoryGirl.create(:full_report, :verified_at => nil)
			expect(Report.completed).not_to include(r)
		end
	end

	#-----------------------------------------------------------------------------

	describe "Creating Visits" do
		it "sets visited_at to be at least 1 minute", :after_commit => true do
			t = Time.zone.now
			r = FactoryGirl.create(:full_report, :completed_at => t, :created_at => t, :location => location)

			r.after_photo 	= Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
			r.elimination_method_id = 1
			r.eliminated_at = t
			r.save!

			original_visit 	 = r.initial_visit
			subsequent_visit = Visit.where("parent_visit_id IS NOT NULL").first
			expect(original_visit.visited_at).to eq(t)
			expect(subsequent_visit.visited_at).to eq(t + Report::ELIMINATION_THRESHOLD)
		end
	end

	#-----------------------------------------------------------------------------

	describe "associated visits", :after_commit => true do
		let(:locations) { [location] }
		let!(:date1)    { DateTime.parse("2014-11-15 11:00") }
		let!(:date2)    { DateTime.parse("2014-11-20 11:00") }

		it "calculates identification type without consider past day's reports" do
			FactoryGirl.create(:full_report, :reporter_id => user.id, :location_id => location.id, :larvae => true,    :created_at => date1)
			FactoryGirl.create(:full_report, :reporter_id => user.id, :location_id => location.id, :protected => true, :created_at => date2)

			visits = Visit.calculate_status_distribution_for_locations(locations, nil, nil, "daily")
			expect(visits).to eq([
				{
					:date=>"2014-11-15",
					:positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
					:total => {:count => 1}
				},
				{
					:date=>"2014-11-20",
					:positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100},
					:total => {:count => 1}
				}
			])
		end
	end

	#-----------------------------------------------------------------------------

end
