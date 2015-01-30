# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:photo_file) { File.open("spec/support/foco_marcado.jpg") }
	let(:location) 	 { FactoryGirl.create(:location, :address => "Test address")}

	it "validates reporter" do
		report = Report.create
		expect(report.errors.full_messages).to include("Reporter é obrigatório")
	end

	it "does not require presence of location" do
		expect {
			FactoryGirl.build(:report, :reporter => user)
		}.to change(Report, :count).by(1)
	end

	it "raises an error if elimination date is before creation date" do
		I18n.locale = "es"

		report = Report.create(:report => "Saw Report",
		:location_id => location.id, :neighborhood_id => Neighborhood.first.id,
		:reporter => user, :breeding_site_id => BreedingSite.first.id, :eliminated_at => Time.now - 3.minutes)

		expect(report.errors.full_messages).to include("Fecha de eliminación can't be before fecha de inspección")
	end
	
	#-----------------------------------------------------------------------------


end
