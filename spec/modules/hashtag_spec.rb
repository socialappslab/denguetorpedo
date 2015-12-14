# -*- encoding : utf-8 -*-
require "rails_helper"

describe Hashtag do
  let(:post) { create(:post, :user_id => 1) }

  it "adds post to hashtag" do
    Hashtag.add_post_to_hashtag(post, "testimonio")
    expect(Hashtag.post_ids_for_hashtag("testimonio")).to include(post.id.to_s)
  end

  it "removes post from hashtag" do
    Hashtag.add_post_to_hashtag(post, "testimonio")
    Hashtag.remove_post_from_hashtag(post, "testimonio")
    expect(Hashtag.post_ids_for_hashtag("testimonio")).not_to include(post.id.to_s)
  end
end
