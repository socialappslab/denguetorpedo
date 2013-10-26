require 'spec_helper'

describe "notices/show" do
  before(:each) do
    @notice = FactoryGirl.create(:notice)
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/#{@notice.title}/)
    rendered.should match(/#{@notice.description}/)
    rendered.should match(/#{@notice.location}/)
  end
end
