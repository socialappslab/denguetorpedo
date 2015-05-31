# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Neighborhoods", :type => :feature do
  let(:n)           { Neighborhood.first}
  let(:user)        { FactoryGirl.create(:user, :profile_photo => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :neighborhood_id => n.id) }
  let!(:post_photo) { Rails.root + "spec/support/foco_marcado.jpg" }
  let(:team)        { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    sign_in(user)
    visit neighborhood_path(n)
  end

  describe "index page" do
    let(:team) { FactoryGirl.create(:team, :name => "Test", :neighborhood_id => n.id) }

    before(:each) do
      skip "Getting odd [GET] errors"
    end

    context "when liking a post", :js => true do
      it "changes the HTML" do
      end

      it "and reloading, it displays the correct like" do
      end
    end
  end

  describe "Viewing the feed", :js => true do
    it "displays a post photo" do
      p = FactoryGirl.create(:post, :neighborhood_id => n.id, :user => user, :content => "Haha", :photo => Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg'))
      visit neighborhood_path(n)
      expect(page).to have_content(p.content)
      expect(page).to have_css(".post-photo img")
    end

  end

  describe "when creating a post", :js => true do
    it "doesn't display a missing image" do
      fill_in "post_content", :with => "Test"
      page.find(".submit-button").click
      expect(page).not_to have_css(".post-photo")
    end
  end

  #---------------------------------------------------------------------------

end
