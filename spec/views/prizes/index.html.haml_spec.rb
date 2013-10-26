require 'spec_helper'

describe "prizes/index" do
  before(:each) do
    @user = FactoryGirl.create(:user)
    @users = User.all
    @prize = FactoryGirl.create(:prize)
    @available = Prize.all
    @individual = Prize.where(community_prize: false)
    @community = Prize.where(community_prize: true)
  end

  it "renders a list of prizes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Prize Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
