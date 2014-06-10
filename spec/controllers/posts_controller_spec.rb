require 'spec_helper'

describe PostsController do
  let(:user) { FactoryGirl.create(:user) }

  #---------------------------------------------------------------------------

  # TODO: For some reason we're getting this error:
  # ArgumentError: wrong number of arguments (1 for 0)

  # context "when liking a post" do
    # let(:post) { FactoryGirl.create(:post) }

    # before(:each) do
    #   cookies[:auth_token] = user.auth_token
    # end
    #
    # it "increments number of likes" do
    #   expect {
    #     post :like, :id => post.id, :user_id => user.id
    #   }.to change(Like, :count).by(1)
    # end
    #
    # it "decrements number of likes" do
    #   Like.create(:user_id => user.id, :likeable_id => post.id, :likeable_type => Post.name)
    #
    #   expect {
    #     post :like, :id => post.id, :user_id => user.id
    #   }.to change(Like, :count).by(-1)
    # end

    # it "creates a Like instance with correct attributes" do
      # post :like

      # like = Like.first
      # expect(like.user_id).to eq(user.id)
      # expect(like.likeable_id).to eq(post.id)
      # expect(like.likeable_type).to eq(post.class.name)
    # end
  # end

  #---------------------------------------------------------------------------
end
