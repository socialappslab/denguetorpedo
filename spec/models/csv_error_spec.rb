# -*- encoding : utf-8 -*-
require "rails_helper"

describe CsvError do
  it "validates on CSV report and error type" do
    e = CsvError.create
    expect(e.errors.keys).to eq([:error_type])
  end
end
