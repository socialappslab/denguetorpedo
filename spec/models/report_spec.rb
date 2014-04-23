# == Schema Information
#
# Table name: reports
#
#  id                        :integer          not null, primary key
#  report                    :text
#  reporter_id               :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  status_cd                 :integer
#  eliminator_id             :integer
#  location_id               :integer
#  before_photo_file_name    :string(255)
#  before_photo_content_type :string(255)
#  before_photo_file_size    :integer
#  before_photo_updated_at   :datetime
#  after_photo_file_name     :string(255)
#  after_photo_content_type  :string(255)
#  after_photo_file_size     :integer
#  after_photo_updated_at    :datetime
#  eliminated_at             :datetime
#  elimination_type          :string(255)
#  elimination_method        :string(255)
#  isVerified                :string(255)
#  verifier_id               :integer
#  verified_at               :datetime
#  resolved_verifier_id      :integer
#  resolved_verified_at      :datetime
#  is_resolved_verified      :string(255)
#  sms                       :boolean          default(FALSE)
#  reporter_name             :string(255)      default("")
#  eliminator_name           :string(255)      default("")
#  verifier_name             :string(255)      default("")
#  completed_at              :datetime
#  credited_at               :datetime
#  is_credited               :boolean
#

require 'spec_helper'

describe Report do

	it "does not require presence of location" do
		r = FactoryGirl.build(:report)

		expect {
			r.save
		}.to change(Report, :count).by(1)
	end

	it "has a valid factory" do
		FactoryGirl.build(:report).should be_valid
	end

  describe "fetching" do
		let(:user) { FactoryGirl.create(:user) }
  	before(:each) do
  		@identified1 = FactoryGirl.create(:report, :elimination_type => "Type")
  		@identified2 = FactoryGirl.create(:report, :elimination_type => "Type")
  		@identified3 = FactoryGirl.create(:report, :elimination_type => "Type")

  		@eliminated1 = FactoryGirl.create(:report, :elimination_method => "Method", :status_cd => 1, :eliminator => user)
  		@eliminated2 = FactoryGirl.create(:report, :elimination_method => "Method", :status_cd => 1, :eliminator => user)
  		@eliminated3 = FactoryGirl.create(:report, :elimination_method => "Method", :status_cd => 1, :eliminator => user)
  	end
  	context "identified reports" do
			it "returns identified results" do
				Report.identified_reports.should ==  [@identified1, @identified2, @identified3]
			end
		end

		context "eliminated_reports" do
			it "returns eliminated results" do
				Report.eliminated_reports.should == [@eliminated1, @eliminated2, @eliminated3]
			end
		end
  end
end
