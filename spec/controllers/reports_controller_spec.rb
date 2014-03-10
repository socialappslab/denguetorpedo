# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	# before(:each) do
	# 	controller.stub(:require_login).and_return(true)
	# 	@report = FactoryGirl.create(:report)
	# end
	# describe "DELETE /reports" do
	# 	it "should deduct points" do
	# 		delete :destroy, id: @report.id
	# 		response.should be_redirect
	# 	end
	# end

	#-----------------------------------------------------------------------------

	context "Creating a new report" do
		render_views

		describe "with errors" do
			it "alerts user if description is not present" do
			end
		end

		describe "successfully" do
			it "creates a report if no map coordinates are present" do
			end
		end
	end

	#-----------------------------------------------------------------------------

end
