require 'spec_helper'

describe Feed do
  before(:each) do
    @file = double('file', size: 0.5.megabytes, content_type: "png", original_filename: "rails")
    Report.any_instance.stub(:before_photo).and_return(@file)
  end

  it "create feeds when posts are created" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)
    u2 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

    p = Post.create!(:user_id => u1.id, :content => "foo", :title => "Title")
    Feed.count.should == 1

    p.children << Post.new(:content => "asdf", :user_id => u1.id, :title => "Title")
    p.children << Post.new(:content => "asdf", :user_id => u2.id, :title => "Title")
    Feed.count.should == 3

    feeds = Feed.all
    feeds[0].target.should == p
    feeds[0].feed_type.should == :post
    feeds[0].user.should == u1
    p.feed.should == feeds[0]
    feeds[1].target.should == p.children[0]
    feeds[1].feed_type.should == :post
    feeds[1].user.should == u1
    p.children[0].feed.should == feeds[1]
    feeds[2].target.should == p.children[1]
    feeds[2].feed_type.should == :post
    feeds[2].user.should == u2
    p.children[1].feed.should == feeds[2]
  end
end
