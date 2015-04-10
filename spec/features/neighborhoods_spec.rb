# encoding: utf-8
require 'spec_helper'

describe "Neighborhoods", :type => :feature do
  let(:n)           { Neighborhood.first}
  let(:user)        { FactoryGirl.create(:user, :profile_photo => File.open(Rails.root + "spec/support/foco_marcado.jpg"), :neighborhood_id => n.id) }
  let!(:post_photo) { Rails.root + "spec/support/foco_marcado.jpg" }
  let(:team)        { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id) }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
  end

  describe "index page" do
    let(:team) { FactoryGirl.create(:team, :name => "Test", :neighborhood_id => n.id) }

    before(:each) do
      pending "Getting odd [GET] errors"
      FactoryGirl.create(:team_membership, :user_id => user.id, :team_id => team.id)
      sign_in(user)
      visit neighborhood_path(n)
    end

    context "when liking a post", :js => true do
      it "changes the HTML" do
      end

      it "and reloading, it displays the correct like" do
      end
    end

  end

  #---------------------------------------------------------------------------

end
