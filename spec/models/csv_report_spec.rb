# -*- encoding : utf-8 -*-
require "rails_helper"

describe CsvReport do
  let(:csv) { FactoryGirl.create(:csv_report) }

  describe "Destroying a CSV report", :after_commit => true do

    it "destroys associated CSV errors" do
      csv.csv_errors << FactoryGirl.create(:csv_error, :csv_report => csv, :error_type => 1)
      expect {
        csv.destroy
      }.to change(CsvError, :count).by(-1)
    end

    it "destroys associated reports" do
      3.times do |index|
        csv.reports << FactoryGirl.create(:full_report, :location_id => 1)
      end

      expect {
        csv.destroy
      }.to change(Report, :count).by(-3)
    end

    it "destroys associated visits" do
      3.times do |index|
        r = create(:full_report, :location_id => 1, :created_at => index.months.ago)
        v = r.find_or_create_first_visit
        r.update_inspection_for_visit(v)
        csv.reports << r
      end

      expect {
        csv.destroy
      }.to change(Visit, :count).by(-3)
    end

    it "destroys associated inspections" do
      3.times do |index|
        r = create(:full_report,:location_id => 1, :created_at => index.months.ago)
        v = r.find_or_create_first_visit()
        r.update_inspection_for_visit(v)
        csv.reports << r
      end


      expect {
        csv.destroy
      }.to change(Inspection, :count).by(-3)
    end
  end
end
