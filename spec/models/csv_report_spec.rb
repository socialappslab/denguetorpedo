# -*- encoding : utf-8 -*-
require "rails_helper"

describe CsvReport do
  it "destroys associated CSV errors" do
    csv = FactoryGirl.create(:csv_report)
    csv.csv_errors << FactoryGirl.create(:csv_error, :csv_report => csv, :error_type => 1)
    expect {
      csv.destroy
    }.to change(CsvError, :count).by(-1)
  end
end
