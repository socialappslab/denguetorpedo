# -*- encoding : utf-8 -*-
require "rails_helper"

describe "City Page", :type => :feature do
  let(:user) { create(:user) }
  let(:city) { create(:city) }

  before(:each) do
    sign_in(user)
  end


  it "renders" do
    visit city_path(city)
    expect(page).to have_content(city.name)
  end

  it "renders even if a post was deleted for a notification" do
    post = create(:post, :user_id => 100)
    un = UserNotification.new(:user_id => user.id)
    un.notification_type = "Post"
    un.notification_id   = post.id
    un.notified_at       = Time.now
    un.medium            = 0
    un.save!
    post.destroy

    visit city_path(city)
    expect(page).to have_content(city.name)
  end
end
