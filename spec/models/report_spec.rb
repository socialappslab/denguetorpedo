# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	before(:each) do
		I18n.locale = I18n.default_locale
	end

	it "validates status" do
		report = Report.create(:reporter_id => 1, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		expect(report.errors.full_messages).to include("Status é obrigatório")
	end

	it "validates reporter" do
		report = Report.create(:status => :reported)
		expect(report.errors.full_messages).to include("Reporter é obrigatório")
	end

	it "does not require presence of location" do
		r = FactoryGirl.build(:report, :neighborhood_id => Neighborhood.first.id, :reporter => user, :breeding_site_id => BreedingSite.first.id)
		expect { r.save! }.to change(Report, :count).by(1)
	end
end
