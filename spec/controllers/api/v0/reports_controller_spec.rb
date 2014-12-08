require 'spec_helper'

describe API::V0::ReportsController do
  let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:device_session) { FactoryGirl.create(:device_session, :user_id => user.id, :token => SecureRandom.uuid)}

  it "returns status 401 if the device token is not present" do
    get :index
    expect(JSON.parse(response.body)["message"]).to include("Device couldn't be authenticated")
    expect(response.status).to eq(401)
  end

  it "returns list of user's reports" do
    request.env["DengueChat-API-V0-Device-Session-Token"] = device_session.token
    get :index, nil
    expect(JSON.parse(response.body)).to eq([])
  end
end
