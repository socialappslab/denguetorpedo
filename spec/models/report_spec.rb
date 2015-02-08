# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:photo_file) { File.open("spec/support/foco_marcado.jpg") }
	let(:location) 	 { FactoryGirl.create(:location, :address => "Test address")}

	it "creates a report" do
		expect {
			FactoryGirl.create(:report, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		}.to change(Report, :count).by(1)
	end

	it "does not require presence of location" do
		expect {
			FactoryGirl.create(:report, :reporter_id => user.id)
		}.to change(Report, :count).by(1)
	end

	it "raises an error if elimination date is before creation date" do
		I18n.locale = "es"

		report = Report.create(:report => "Saw Report",
		:location_id => location.id, :neighborhood_id => Neighborhood.first.id,
		:reporter => user, :breeding_site_id => BreedingSite.first.id, :eliminated_at => Time.now - 3.minutes)

		expect(report.errors.full_messages).to include("Fecha de eliminación can't be before fecha de inspección")
	end

	it "raises an error if elimination date is before creation date" do
		I18n.locale = "es"

		report = Report.create(:report => "Saw Report",
		:location_id => location.id, :neighborhood_id => Neighborhood.first.id,
		:reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => Time.now + 1.minute)

		expect(report.errors.full_messages).to include("Fecha de inspección can't be in the future")
	end

	#-----------------------------------------------------------------------------

	describe "associated visits", :after_commit => true do
		let(:locations) { [location] }
		let!(:date1)    { DateTime.parse("2014-11-15 11:00") }
		let!(:date2)    { DateTime.parse("2014-11-20 11:00") }

		it "calculates identification type without consider past day's reports" do
			FactoryGirl.create(:report, :reporter_id => user.id, :location_id => location.id, :larvae => true,    :created_at => date1)
			FactoryGirl.create(:report, :reporter_id => user.id, :location_id => location.id, :protected => true, :created_at => date2)

			visits = Visit.calculate_daily_time_series_for_locations_start_time_and_visit_types(locations)
			expect(visits).to eq([
				{
					:date=>"2015-11-15",
					:positive=>{:count=>1, :percent=>100}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>0, :percent=>0},
					:total => {:count => 1}
				},
				{
					:date=>"2015-11-20",
					:positive=>{:count=>0, :percent=>0}, :potential=>{:count=>0, :percent=>0}, :negative=>{:count=>1, :percent=>100},
					:total => {:count => 1}
				}
			])
		end
	end

	#-----------------------------------------------------------------------------

end
