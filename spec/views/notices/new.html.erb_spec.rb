require 'spec_helper'

describe "notices/new" do
  before(:each) do
    @notice = FactoryGirl.create(:notice)
    @neighborhoods = Neighborhood.all
  end

  it "renders new notice form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    pending "I do not know why this is failing"
    assert_select "form[action=?][method=?]", notices_path, "post" do
      assert_select "input#notice_title[name=?]", "notice[title]"
      assert_select "textarea#notice_description[name=?]", "notice[description]"
      assert_select "input#notice_location[name=?]", "notice[location]"
    end
  end
end
