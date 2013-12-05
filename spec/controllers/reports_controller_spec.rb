require 'spec_helper'

describe ReportsController do
	before(:each) do
		controller.stub(:require_login).and_return(true)
		@report = FactoryGirl.create(:report)
	end
	describe "DELETE /reports" do
		it "should deduct points" do
			delete :destroy, id: @report.id
			response.should be_redirect
		end
	end
end
