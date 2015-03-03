# encoding: utf-8
require 'spec_helper'

describe "Neighborhoods", :type => :feature do
  describe "index page" do
    let(:n)    { Neighborhood.first}
    let(:user) { FactoryGirl.create(:user, :profile_photo => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :neighborhood_id => n.id) }
    let(:team) { FactoryGirl.create(:team, :name => "Test", :neighborhood_id => n.id) }

    before(:each) do
      pending "Getting odd [GET] errors"
      FactoryGirl.create(:team_membership, :user_id => user.id, :team_id => team.id)
      sign_in(user)
      visit neighborhood_path(n)
    end

    context "when liking a post", :js => true do
      it "updates the counter" do
        save_and_open_page
      end

      it "changes the HTML" do
      end

      it "and reloading, it displays the correct like" do
      end
    end
  end

  #---------------------------------------------------------------------------

end
