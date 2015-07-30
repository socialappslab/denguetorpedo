# -*- encoding : utf-8 -*-

require "rails_helper"
require 'rack/test'

describe Inspection do
  let(:user) 			 { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:date1)     { DateTime.parse("2014-10-21 11:00") }
  let(:location) 	 { FactoryGirl.create(:location, :address => "Test address")}
  let(:visit)      { FactoryGirl.create(:visit, :location_id => location.id, :visited_at => date1) }
  let(:report)     { FactoryGirl.create(:report, :reporter => user) }
  let(:new_report) { FactoryGirl.create(:full_report) }

  it "avoids creating duplicate records" do
    FactoryGirl.create(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    r = FactoryGirl.build(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    expect {
      r.save
    }.not_to change(Inspection, :count)
  end

  #-----------------------------------------------------------------------------

  it "destroy visit if it's last visit" do
    inspection = FactoryGirl.create(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    expect {
      inspection.destroy
    }.to change(Visit, :count).by(-1)
  end

  it "doesn't destroy visit if there is another inspection associated with visit" do
    inspection = FactoryGirl.create(:inspection, :visit_id => visit.id, :report_id => report.id, :identification_type => Inspection::Types::POSITIVE)
    inspection = FactoryGirl.create(:inspection, :visit_id => visit.id, :report_id => new_report.id, :identification_type => Inspection::Types::POSITIVE)
    expect {
      inspection.destroy
    }.not_to change(Visit, :count)
  end

end
