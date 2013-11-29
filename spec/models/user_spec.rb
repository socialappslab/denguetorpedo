require 'spec_helper'
require "cancan/matchers"

describe User do
	before(:all) do
		@user = FactoryGirl.create(:user)
	end

	describe "abilities" do
		subject(:ability) { Ability.new(user)}
		let (:user) { nil }

		context "when user is an admin" do
			let(:user) { FactoryGirl.create(:admin) }
			it { should be_able_to(:assign_roles, @user)}
			it { should be_able_to(:edit, @user)}
		end

		context "when user is a resident" do
			let(:user) { FactoryGirl.create(:user)}
			it { should_not be_able_to(:assing_roles, @user)}
			it { should_not be_able_to(:edit, @user) }
		end
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
		it "reports should have right description" do
			@report.report.should == "Rua Tatajuba 50"
		end

	end
end
