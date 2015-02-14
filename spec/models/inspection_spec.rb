# encoding: utf-8

require 'spec_helper'
require 'rack/test'

describe Inspection do
  let(:user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:date1)    { DateTime.parse("2014-10-21 11:00") }
  let(:location) 	 { FactoryGirl.create(:location, :address => "Test address")}
  let(:visit)  { FactoryGirl.create(:visit, :location_id => location.id, :visited_at => date1) }
  let(:report) { FactoryGirl.create(:report, :reporter => user) }

  it "avoids creating duplicate records" do
    FactoryGirl.create(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    r = FactoryGirl.build(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    expect {
      r.save
    }.not_to change(Inspection, :count)
  end

  #-----------------------------------------------------------------------------

end
