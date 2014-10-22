# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

	it "validates reporter" do
		report = Report.create
		expect(report.errors.full_messages).to include("Reporter é obrigatório")
	end

	it "does not require presence of location" do
		r = FactoryGirl.build(:report, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		expect { r.save! }.to change(Report, :count).by(1)
	end
end
