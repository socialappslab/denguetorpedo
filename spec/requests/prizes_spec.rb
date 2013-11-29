require 'spec_helper'

describe "Prizes" do
  describe "GET /prizes" do
  	before(:each) do
    
	    @location = Location.create(latitude: 0, longitude: 0)
	    @house = FactoryGirl.create(:house, location_id: @location.id)
	    @user = FactoryGirl.create(:user, house_id: @house.id)
	    @prize = FactoryGirl.create(:prize)
	    @redetrel_house = FactoryGirl.create(:house, name: "Rede Trel")
	    @redetrel = FactoryGirl.create(:user, house: @redetrel_house)
	  end

    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      
	    # @prize.user.house.location.stub(:latitude).and_return(0)
     #  @prize.user.house.location.stub(:longitude).and_return(0)
      get prizes_path
      response.status.should be(200)
    end
  end
end
