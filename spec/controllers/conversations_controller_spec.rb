# # -*- encoding : utf-8 -*-
# require "rails_helper"
#
# describe ConversationsController do
#   let(:user)         { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
#   let(:other_user)   { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
#   let(:conversation) { FactoryGirl.create(:conversation) }
#   let!(:user_notification) { FactoryGirl.create(:message_notification, :user_id => user.id, :notification_id => 1) }
#
#   before(:each) do
#     cookies[:auth_token] = user.auth_token
#   end
#
#   it "updates all notifications to 'viewed'" do
#     expect(user.notifications.where(:seen_at => nil).count).to eq(1)
#     get "index"
#
#     expect(user.notifications.reload.where(:seen_at => nil).count).to eq(0)
#   end
# end
