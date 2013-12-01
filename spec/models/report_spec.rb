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

	it "has a valid factory"
  describe "when newly created" do
  	let(:report) { FactoryGirl.build(:report)}
  	it { should_not be_sms }
  end

  describe "when a report is sent by SMS" do
  	let(:report) { FactoryGirl.build(:sms)}
  	it { should be_sms }
  end
end
