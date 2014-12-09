require 'spec_helper'

describe API::V0::ReportsController do
  let!(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let!(:device_session) { FactoryGirl.create(:device_session, :user_id => user.id, :token => SecureRandom.uuid)}
  let(:photo_file) 			{ File.open("spec/support/foco_marcado.jpg") }
  let(:uploaded_photo)   { ActionDispatch::Http::UploadedFile.new(:tempfile => photo_file, :filename => File.basename(photo_file), :content_type => 'image/jpg') }

  it "returns status 401 if the device token is not present" do
    get :index
    expect(JSON.parse(response.body)["message"]).to include("Device couldn't be authenticated")
    expect(response.status).to eq(401)
  end

  it "returns list of user's reports" do
    request.env["DengueChat-API-V0-Device-Session-Token"] = device_session.token
    get :index, nil
    expect(JSON.parse(response.body)).to eq("reports" => [])
  end

  context "when creating a report" do
    before(:each) do
      request.env["DengueChat-API-V0-Device-Session-Token"] = device_session.token
    end

    it "increments Report count on successful attempt" do
      expect {
        post :create, :report => {:report => "Hello", :breeding_site_id => BreedingSite.first.id, :address => "N0032", :before_photo => uploaded_photo}
      }.to change(Report, :count).by(1)
    end
  end
end
