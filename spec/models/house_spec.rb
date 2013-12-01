# == Schema Information
#
# Table name: houses
#
#  id                         :integer          not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  name                       :string(255)
#  featured_event_id          :integer
#  location_id                :integer
#  profile_photo_file_name    :string(255)
#  profile_photo_content_type :string(255)
#  profile_photo_file_size    :integer
#  profile_photo_updated_at   :datetime
#  phone_number               :string(255)      default("")
#  house_type                 :string(255)      default("morador")
#  user_id                    :integer
#

require 'spec_helper'

describe House do
	before(:each) do
		@user = FactoryGirl.create(:user)
		@house = FactoryGirl.build(:house, user_id: @user.id)
	end
	context "with valid attributes" do
		it "should be valid" do
			@house.should be_valid
		end

		context "when created" do
			it "should increase house count by 1" do
			end
		end
	end

	context "with invalid attributes" do
		context "without a name" do
			before(:each) do
				@house.name = nil
			end
			it "should not be valid" do
				@house.should_not be_valid
			end
		end
	end
	
end
