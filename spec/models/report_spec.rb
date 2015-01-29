# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Report do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
	let(:location) { FactoryGirl.create(:location, :address => "Test address")}

	#-----------------------------------------------------------------------------

	it "does not require presence of location" do
		expect {
			FactoryGirl.build(:report, :reporter => user)
		}.to change(Report, :count).by(1)
	end

	#-----------------------------------------------------------------------------


end
