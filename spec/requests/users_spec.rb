require 'spec_helper'


def login(user)
	post session_path, email: user.email, password: 'denguewarrior'
end
describe "Users" do
	before(:all) do
		@user = FactoryGirl.create(:user)
		@admin = FactoryGirl.create(:admin)
	end
  describe "GET /users" do
    it "should not work for ordinary users" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      login(@user)
      get users_path
      response.status.should be(401)
    end

    it "should work for admin users" do
    	login(@admin)
    	get users_path
    	response.status.should be(200)
    end
  end


  describe "EDIT /users" do
  	it "should work for all users" do
  		login(@user)
  		get edit_user_path(@user)
  		response.status.should be(200)
  	end
  end
end