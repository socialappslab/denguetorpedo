require 'spec_helper'

describe "prizes/show" do
  before(:each) do
    
    @house = FactoryGirl.create(:house)
    @user = FactoryGirl.create(:user, house_id: @house.id)
    @users = User.all
    @prize = FactoryGirl.create(:prize, user_id: @user.id)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Prize Name/)
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/3/)
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
  end
end
