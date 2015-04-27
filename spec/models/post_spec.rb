# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: posts
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  title      :string(255)
#  content    :text
#  type_cd    :integer
#  parent_id  :integer
#  lft        :integer
#  rgt        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wall_id    :integer
#  wall_type  :string(255)
#

require 'spec_helper'

describe Post do
  it "can create simple posts" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)
    p1 = Post.create!(:content => "testing", :user_id => u1.id, :title => "Title1")
    p2 = Post.create!(:content => "testing1", :user_id => u1.id, :title => "Title2")
    p3 = Post.create!(:content => "testing2", :user_id => u1.id, :title => "Title3")
    p4 = Post.create!(:content => "testing3", :user_id => u1.id, :title => "Title4")

    Post.count.should == 4
    for p in Post.all
      p.user.should == u1
    end
  end

  it "can have ancestors and descendants" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

    p1 = Post.create!(:content => "testing",  :title => "title1", :user_id => u1.id)
    p2 = Post.create!(:content => "testing1", :title => "title2", :user_id => u1.id)
    p3 = Post.create!(:content => "testing2", :title => "title3", :user_id => u1.id)
    p4 = Post.create!(:content => "testing3", :title => "title4", :user_id => u1.id)
    p5 = Post.create!(:content => "testing3", :title => "title5", :user_id => u1.id)
    p6 = Post.create!(:content => "testing3", :title => "title6", :user_id => u1.id)

    [p1, p2, p3, p4, p5, p6].each do |p|
      p.reload
      p.user.should == u1
    end
  end

  it "should fail validations" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

    p = Post.create :content => "asdfsdf"
    p.valid?.should be_false

    p = Post.create :user_id => 1
    p.valid?.should be_false

    p = Post.create :content => "sfsdf", :user_id => u1.id, :title => "With title"
    p.valid?.should be_true
  end
end
