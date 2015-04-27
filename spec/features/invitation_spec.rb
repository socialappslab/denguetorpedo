# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Contact Form for Future Communities", :type => :feature do
  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  it "sends an email to denguetorpedo@gmail.com" do
    expect(ActionMailer::Base.deliveries.count).to eq(0)

    visit neighborhood_invitation_path
    fill_in "feedback_title", :with => "Hello"
    fill_in "feedback_email", :with => "test@denguetorpedo.com"
    fill_in "feedback_name", :with => "Test"
    fill_in "feedback_message", :with => "Test again"
    page.find(".submit-button").click

    expect(ActionMailer::Base.deliveries.count).to eq(1)

    email = ActionMailer::Base.deliveries.first
    expect(email.to).to include("denguetorpedo@gmail.com")
    expect(email.from).to include("test@denguetorpedo.com")
  end
end
