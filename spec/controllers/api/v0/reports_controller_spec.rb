# -*- encoding : utf-8 -*-
require "rails_helper"

describe API::V0::ReportsController do
  let!(:user)           { FactoryGirl.create(:user) }
  let!(:device_session) { FactoryGirl.create(:device_session, :user_id => user.id, :token => SecureRandom.uuid)}
  let(:base64_image) 	  { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:site)            { FactoryGirl.create(:breeding_site) }

  it "returns status 401 if the device token is not present" do
    get :index
    expect(JSON.parse(response.body)["message"]).to include("Device couldn't be authenticated")
    expect(response.status).to eq(401)
  end

  it "returns list of user's reports" do
    request.env["DengueChat-API-V0-Device-Session-Token"] = device_session.token
    get :index, nil, :format => :json
    expect(JSON.parse(response.body)).to eq("reports" => [])
  end

  context "when creating a report" do
    before(:each) do
      request.env["DengueChat-API-V0-Device-Session-Token"] = device_session.token
    end

    it "increments Report count on successful attempt" do
      expect {
        post :create, :report => {:report => "Hello", :breeding_site_id => site.id, :address => "N0032", :before_photo => base64_image}
      }.to change(Report, :count).by(1)
    end
  end
end
