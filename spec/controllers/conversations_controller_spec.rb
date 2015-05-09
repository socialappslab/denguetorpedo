# -*- encoding : utf-8 -*-
require "rails_helper"

describe ConversationsController do
  let(:user)         { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:other_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:conversation) { FactoryGirl.create(:conversation) }
  let!(:user_notification) { FactoryGirl.create(:user_notification, :user_id => user.id, :notification_type => UserNotification::Types::MESSAGE) }

  before(:each) do
    cookies[:auth_token] = user.auth_token
  end

  it "updates all notifications to 'viewed'" do
    expect(user.user_notifications.where(:viewed => true).count).to eq(0)
    get "index"
    expect(user.user_notifications.reload.where(:viewed => true).count).to eq(1)
  end
end
