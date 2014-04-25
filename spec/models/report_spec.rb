require 'spec_helper'

describe Report do

	it "does not require presence of location" do
		r = FactoryGirl.build(:report)
		expect { r.save }.to change(Report, :count).by(1)
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

  		@eliminated1 = FactoryGirl.create(:report, :elimination_method => "Method", :status => Report::STATUS[:eliminated], :eliminator => user)
  		@eliminated2 = FactoryGirl.create(:report, :elimination_method => "Method", :status => Report::STATUS[:eliminated], :eliminator => user)
  		@eliminated3 = FactoryGirl.create(:report, :elimination_method => "Method", :status => Report::STATUS[:eliminated], :eliminator => user)
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
