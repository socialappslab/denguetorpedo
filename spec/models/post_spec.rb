require "rails_helper"

describe Post do
  it "can create simple posts" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)
    p1 = Post.create!(:content => "testing", :user_id => u1.id, :title => "Title1")
    p2 = Post.create!(:content => "testing1", :user_id => u1.id, :title => "Title2")
    p3 = Post.create!(:content => "testing2", :user_id => u1.id, :title => "Title3")
    p4 = Post.create!(:content => "testing3", :user_id => u1.id, :title => "Title4")

    expect(Post.count).to eq(4)
    for p in Post.all
      expect(p.user).to eq(u1)
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
      expect(p.user).to eq(u1)
    end
  end

  it "should fail validations" do
    u1 = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)

    p = Post.create :content => "asdfsdf"
    expect(p.valid?).to be_falsey

    p = Post.create :user_id => 1
    expect(p.valid?).to be_falsey

    p = Post.create :content => "sfsdf", :user_id => u1.id, :title => "With title"
    expect(p.valid?).to be_truthy
  end

  it "destroys associated comments when a post is deleted" do
    u = FactoryGirl.create(:user)
    p = FactoryGirl.create(:post, :content => "test", :user_id => u.id)
    FactoryGirl.create(:comment, :user_id => u.id, :content => "test", :commentable_id => p.id, :commentable_type => "Post")
    expect {
      p.destroy
    }.to change(Comment, :count).by(-1)
  end

  it "destroys associated likes when a post is deleted" do
    u = FactoryGirl.create(:user)
    p = FactoryGirl.create(:post, :content => "test", :user_id => u.id)
    FactoryGirl.create(:like, :user_id => u.id, :likeable_id => p.id, :likeable_type => "Post")
    expect {
      p.destroy
    }.to change(Like, :count).by(-1)

  end

  describe "Adding hashtags", :after_commit => true do
    it "adds the post to an accepted hashtag after creation" do
      post = build(:post, :user_id => 1, :content => "Hello #testimonio")
      post.save!
      expect(Hashtag.post_ids_for_hashtag("testimonio")).to include(post.id.to_s)
    end

    it "does not add hashtag after just saving" do
      post = create(:post, :user_id => 1, :content => "Hello")
      post.content = "Test #testimonio"; post.save
      expect(Hashtag.post_ids_for_hashtag("testimonio")).not_to include(post.id.to_s)
    end
  end

  describe "Removing hashtags", :after_commit => true do
    let!(:post) { create(:post, :user_id => 1, :content => "Hello #testimonio")}

    it "removes the post from the accepted hashtag" do
      post.destroy
      expect(Hashtag.post_ids_for_hashtag("testimonio")).not_to include(post.id.to_s)
    end
  end
end
