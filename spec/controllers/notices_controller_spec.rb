# -*- encoding : utf-8 -*-
require "rails_helper"

describe NoticesController do
  let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:valid_attributes) { { title: "Hihi", description: "Description", summary: "Summary", neighborhood_id: Neighborhood.first.id, institution_name: "DT Headquarter"} }

  #---------------------------------------------------------------------------

  context "when liking the news" do
  #   let(:news) { FactoryGirl.create(:notice) }
  #
  #   before(:each) do
  #     cookies[:auth_token] = user.auth_token
  #   end
  #
  #   it "increments number of likes" do
  #     expect {
  #       post :like, :id => news.id
  #     }.to change(Like, :count).by(1)
  #   end
  #
  #   it "decrements number of likes" do
  #     Like.create(:user_id => user.id, :likeable_id => news.id, :likeable_type => Notice.name)
  #
  #     expect {
  #       post :like, :id => news.id
  #     }.to change(Like, :count).by(-1)
  #   end
  #
  #   it "creates a Like instance with correct attributes" do
  #     post :like, :id => news.id
  #
  #     like = Like.first
  #     expect(like.user_id).to eq(user.id)
  #     expect(like.likeable_id).to eq(news.id)
  #     expect(like.likeable_type).to eq(news.class.name)
  #   end
  end

  #---------------------------------------------------------------------------

end
