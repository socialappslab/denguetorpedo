# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:photo_file) 			{ File.open("spec/support/foco_marcado.jpg") }

	it "validates reporter" do
		report = Report.create
		expect(report.errors.full_messages).to include("Reporter é obrigatório")
	end

	it "does not require presence of location" do
		r = FactoryGirl.build(:report, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		expect { r.save! }.to change(Report, :count).by(1)
	end


	#-----------------------------------------------------------------------------

	context "Setting Location Status", :after_commit => true do
		let(:location) { FactoryGirl.create(:location, :address => "Test address")}
		before(:each) do
			20.times do |index|
				report = FactoryGirl.create(:report, :report => "Saw Report ##{index}", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
				report.eliminated_at = Time.now - index.days.ago
				report.after_photo   = photo_file
				report.elimination_method_id = BreedingSite.first.elimination_methods.first.id
				report.save!
			end
		end

		it "sets location status to positive if at least one report is positive" do
			FactoryGirl.create(:report, :report => "Saw Report", :location_id => location.id, :larvae => true, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
			puts "CREATED>.."
			expect(location.reload.status).to eq(LocationStatus::Types::POSITIVE)
		end

		it "sets location status to potential if at least one report is potential" do
			FactoryGirl.create(:report, :report => "Saw Report", :location_id => location.id, :larvae => false, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
			expect(location.reload.status).to eq(LocationStatus::Types::POTENTIAL)
		end

		it "sets location status to clean if location has been clean for more than 14 days" do
			expect(location.reload.status).to eq(LocationStatus::Types::CLEAN)
		end
	end

	#-----------------------------------------------------------------------------


end
