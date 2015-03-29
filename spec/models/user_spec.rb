# encoding: utf-8

require 'spec_helper'
require "cancan/matchers"

describe User do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

	before(:each) do
		I18n.default_locale = User::Locales::SPANISH
	end

	it "validates presence of neighborhood" do
		I18n.locale = I18n.default_locale
		user.neighborhood_id = nil
		user.save
		expect(user.errors.full_messages).to include("Comunidad es obligatorio")
	end

	describe "abilities" do
    before(:each) do
      pending "Fix CanCan roles"
    end

		context "when user is a coordinator" do
			let(:user) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id) }
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
			@report = user.build_report_via_sms({
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

	describe "when destroying a user" do
		let!(:notification) { FactoryGirl.create(:user_notification, :user_id => user.id, :notification_type => UserNotification::Types::MESSAGE)}

		it "destroys all associated notifications" do
			expect {
				user.destroy
			}.to change(UserNotification, :count).by(-1)
		end

	end
end
