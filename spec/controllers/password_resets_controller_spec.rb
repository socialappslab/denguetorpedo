require 'spec_helper'

describe PasswordResetsController do
  let(:user) { FactoryGirl.create(:user, :email => "test@mailinator.com", :neighborhood_id => Neighborhood.first.id) }

  it "sends a password reset email" do
    expect {
      post :create, :email => user.email
    }.to change(ActionMailer::Base.deliveries, :count).by(1)
  end

  it "avoids sending an email if user is not found" do
    expect {
      post :create, :email => "test@mailinator.com"
    }.not_to change(ActionMailer::Base.deliveries, :count)
  end

end
