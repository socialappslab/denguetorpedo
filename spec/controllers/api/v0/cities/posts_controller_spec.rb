# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::Cities::PostsController do
  render_views
  let(:city)  { create(:city) }
  let(:user)  { FactoryGirl.create(:user) }


  #----------------------------------------------------------------------------

  describe "Loading posts" do
    let(:neighborhood) { create(:neighborhood, :city => city) }
    let!(:post) { create(:post, :user_id => user.id, :neighborhood_id => neighborhood.id) }

    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "successfully loads" do
      get :index, :city_id => city.id, :hashtag => "", :format => :json
      posts = JSON.parse(response.body)["posts"]
      expect(posts.count).to eq(1)
    end

    it "filters by hashtag" do
      get :index, :city_id => city.id, :hashtag => "testimonio", :format => :json
      posts = JSON.parse(response.body)["posts"]
      expect(posts).to eq([])
    end
  end

  #----------------------------------------------------------------------------

end
