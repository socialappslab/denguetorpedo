# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Contact Form for Future Communities", :type => :feature do
  it "sends an email to denguetorpedo@gmail.com" do
    Sidekiq::Testing.fake!

    expect {
      visit invitation_neighborhoods_path
      fill_in "feedback_email", :with => "test@denguetorpedo.com"
      fill_in "feedback_name", :with => "Test"
      fill_in "feedback_message", :with => "Test again"
      page.find(".submit-button").click
    }.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)

    Sidekiq::Extensions::DelayedMailer.drain
  end
end
