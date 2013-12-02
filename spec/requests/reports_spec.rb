require 'spec_helper'

describe "Reports" do
  describe "GET /reports" do
  	before(:each) do
  		@user = FactoryGirl.create(:user)
  		post session_path, email: @user.email, password: 'denguewarrior'
  	end
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      
      get reports_path
      response.status.should be(200)
    end
  end
end
