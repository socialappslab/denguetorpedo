require 'spec_helper'

describe "Prizes" do
  describe "GET /prizes" do

    before(:each) do
      @user = FactoryGirl.create(:user)
      post session_path, email: @user.email, password: 'denguewarrior'
    end

    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      
      get prizes_path
      response.status.should be(200)
    end
  end
end
