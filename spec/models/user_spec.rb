

require 'spec_helper'
require "cancan/matchers"

describe User do
	let(:user) { FactoryGirl.create(:user) }

	describe "abilities" do
    before(:each) do
      pending "Fix CanCan roles"
    end

		context "when user is an admin" do
			let(:user) { FactoryGirl.create(:admin) }
			it { should be_able_to(:assign_roles, user)}
			it { should be_able_to(:edit, user)}
		end

		context "when user is a resident" do
			it { should_not be_able_to(:assign_roles, user)}
			it { should_not be_able_to(:edit, user) }
		end
	end

	context "when sends an sms by phone" do
		before(:each) do
			@report = user.report_by_phone({
        :from => user.phone_number, :body => "Rua Tatajuba 50"
      })
		end

		it "sms field should be true" do
			@report.sms.should be_true
		end

		it "should report successfully" do
			@report.should be_valid
		end

		it "should belong to the user" do
			@report.reporter.should equal(user)
		end
		it "reports should have right description" do
			@report.report.should == "Rua Tatajuba 50"
		end

	end
end
