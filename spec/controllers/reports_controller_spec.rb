# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	#-----------------------------------------------------------------------------

	context "Creating a new report" do
		render_views

		describe "with errors" do
			it "alerts user if description is not present" do
			end
		end

		describe "successfully" do
			let(:location) { FactoryGirl.create(:location) }

			it "creates a report if no map coordinates are present" do
			end

			it "finds map coordinates even if user didn't submit them" do
				expect(location.latitude).to  eq(nil)
				expect(location.longitude).to eq(nil)

				post :create, :street_type => location.street_type, :street_name => location.street_name, :street_number => location.street_number,
				:report => { :report => "", :before_photo => "Test" }

				location.reload
				expect(location.latitude).to  eq(680291.2151545063)
				expect(location.longitude).to eq(7471401.29586681)
			end
		end
	end

	#-----------------------------------------------------------------------------

end
