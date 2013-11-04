require 'spec_helper'

describe User do
	before(:all) do
		@user = FactoryGirl.create(:user)
	end

	context "when sends an sms by phone" do
		before(:all) do
			@params = { from: @user.phone_number, body: "Rua Tatajuba 50" }
			@report = @user.report_by_phone(@params)
		end

		it "sms field should be true" do
			@report.sms.should be_true
		end

		it "should report successfully" do		
			@report.should be_valid
		end
		
		it "should belong to the user" do
			@report.reporter.should equal(@user)
		end
		it "reports should have right address fields" do
			@report.location.street_type.should == "Rua"
			@report.location.street_name.should == "Tatajuba"
			@report.location.street_number.should == "50"
		end

	end
end
