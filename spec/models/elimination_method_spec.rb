# -*- encoding : utf-8 -*-
require "rails_helper"

describe EliminationMethod do
  it "validates presence of points" do
    expect {
      FactoryGirl.create(:elimination_method, :points => nil)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "validates numericality of points" do
    expect {
      FactoryGirl.create(:elimination_method, :points => "haha")
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
