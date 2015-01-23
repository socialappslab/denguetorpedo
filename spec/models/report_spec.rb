# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:photo_file) 			{ File.open("spec/support/foco_marcado.jpg") }
	let(:location) { FactoryGirl.create(:location, :address => "Test address")}

	it "does not require presence of location" do
		r = FactoryGirl.build(:report, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		expect { r.save! }.to change(Report, :count).by(1)
	end


	#-----------------------------------------------------------------------------

	context "when creating reports", :after_commit => true do
		let!(:time_ago)	{ Time.now - 100.days }
		
		it "creates a new visit instance" do
			expect {
				FactoryGirl.create(:report, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
			}.to change(Visit, :count).by(1)
		end

		it "sets the correct identification time on Visit" do
			report = FactoryGirl.create(:report, :larvae => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)

			v = Visit.first
			expect(v.identified_at).to eq(time_ago)
		end

		it "sets the correct identification type on positive reports" do
			report = FactoryGirl.create(:report, :larvae => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)

			v = Visit.first
			expect(v.identification_type).to eq(Report::Status::POSITIVE)
		end

		it "sets the correct identification type on potential reports" do
			report = FactoryGirl.create(:report, :larvae => false, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)

			v = Visit.first
			expect(v.identification_type).to eq(Report::Status::POTENTIAL)
		end

		it "sets the correct identification type on negative reports" do
			report = FactoryGirl.create(:report, :protected => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)

			v = Visit.first
			expect(v.identification_type).to eq(Report::Status::NEGATIVE)
		end

		it "sets the correct location" do
			report = FactoryGirl.create(:report, :protected => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)

			v = Visit.first
			expect(v.location_id).to eq(location.id)
		end

		it "associates the report to the visit" do
			report = FactoryGirl.create(:report, :protected => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :created_at => time_ago)
			expect(report.reload.visit_id).to eq(Visit.first.id)
		end
	end

	context "when eliminating reports", :after_commit => true do
		let!(:elimination_time) { Time.now - 3.days }
		let(:report) { FactoryGirl.create(:report, :larvae => true, :report => "Saw Report", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id, :elimination_method_id => BreedingSite.first.elimination_methods.first.id, :created_at => Time.now - 100.days) }

		before(:each) do
			# This invokes after_commit callback to create a Visit instance.
			report.save(:validate => false)
			report.eliminator_id = user.id
			report.eliminated_at = elimination_time
		end

		it "never creates a new Visit instance" do
			expect {
				report.save(:validate => false)
			}.not_to change(Visit, :count)
		end

		it "updates the cleaning time" do
			report.save(:validate => false)
			v = Visit.first
			expect(v.cleaned_at).to eq(elimination_time)
		end
	end


	# before(:each) do
	# 	20.times do |index|
	# 		report = FactoryGirl.create(:report, :report => "Saw Report ##{index}", :location_id => location.id, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
	# 		report.eliminated_at = Time.now - index.days.ago
	# 		report.after_photo   = photo_file
	# 		report.elimination_method_id = BreedingSite.first.elimination_methods.first.id
	# 		report.save!
	# 	end
	# end
	#
	#-----------------------------------------------------------------------------


end
