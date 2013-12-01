# == Schema Information
#
# Table name: users
#
#  id                         :integer          not null, primary key
#  username                   :string(255)
#  password_digest            :string(255)
#  auth_token                 :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  email                      :string(255)
#  password_reset_token       :string(255)
#  password_reset_sent_at     :datetime
#  phone_number               :string(255)
#  points                     :integer          default(0), not null
#  house_id                   :integer
#  profile_photo_file_name    :string(255)
#  profile_photo_content_type :string(255)
#  profile_photo_file_size    :integer
#  profile_photo_updated_at   :datetime
#  is_verifier                :boolean          default(FALSE)
#  is_fully_registered        :boolean          default(FALSE)
#  is_health_agent            :boolean          default(FALSE)
#  first_name                 :string(255)
#  middle_name                :string(255)
#  last_name                  :string(255)
#  nickname                   :string(255)
#  display                    :string(255)      default("firstmiddlelast")
#  role                       :string(255)      default("morador")
#  total_points               :integer          default(0)
#  gender                     :boolean          default(TRUE)
#  is_blocked                 :boolean          default(FALSE)
#  carrier                    :string(255)      default("")
#  prepaid                    :boolean
#

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
