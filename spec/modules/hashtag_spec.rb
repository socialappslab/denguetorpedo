# -*- encoding : utf-8 -*-
require "rails_helper"

describe Hashtag do
  let(:post) { create(:post, :user_id => 1) }

  it "adds post to hashtag" do
    Hashtag.add_post_to_hashtag(post, "testimonial")
    expect(Hashtag.posts_for_hashtag("testimonial")).to include(post)
  end

  it "removes post from hashtag" do
    Hashtag.add_post_to_hashtag(post, "testimonial")
    Hashtag.remove_post_from_hashtag(post, "testimonial")
    expect(Hashtag.posts_for_hashtag("testimonial")).not_to include(post)
  end
end
