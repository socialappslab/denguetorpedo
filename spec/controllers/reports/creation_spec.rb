# -*- encoding : utf-8 -*-
require "rails_helper"

describe ReportsController do
	let!(:neighborhood)    { FactoryGirl.create(:neighborhood) }
	let(:user) 						 { FactoryGirl.create(:user) }
	let(:elimination_type) { FactoryGirl.create(:breeding_site) }
	let(:location_hash) 	 { { :address => "Rua Darci Vargas 45", :latitude => "50.0", :longitude => "40.0" }.with_indifferent_access }
  let(:report_params) 	 { { :report => "This is a description",  "created_at(3i)"=>"9", "created_at(2i)"=>"8", "created_at(1i)"=>"2015", :protected => false, :larvae => true, :pupae => true, :reporter_id => user.id, :compressed_photo => base64_image_string, :breeding_site_id => elimination_type.id }.with_indifferent_access }

  before(:each) do
    cookies[:auth_token] = user.auth_token
  end

	#-----------------------------------------------------------------------------

	describe "Visiting New Report Page" do
		render_views

		it "renders" do
			get :new, :neighborhood_id => neighborhood.id
			expect(response.body).not_to eq("")
		end
	end

	#-----------------------------------------------------------------------------

  it "increments Report" do
		expect {
			post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
		}.to change(Report, :count).by(1)
	end

  it "sets attributes correctly" do
    post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params

    r = Report.last
    ["report", "protected", "larvae", "pupae", "reporter_id", "breeding_site_id"].each do |attr|
      expect(r.attributes[attr]).to eq(report_params[attr])
    end

		expect(r.reload.created_at.strftime("%Y-%m-%d")).to eq("2015-08-09")
  end

  it "creates a report if no map coordinates are present" do
		location_hash.delete(:latitude)
		location_hash.delete(:longitude)

		expect {
			post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
		}.to change(Report, :count).by(1)
	end

  it "sets verified_at" do
		post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
		expect(Report.last.verified_at).not_to eq(nil)
	end

  it "allows to save without before photo" do
    report_params.delete(:compressed_photo)

    expect {
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 0, :report => report_params
    }.to change(Report, :count).by(1)
  end

	it "awards submission points" do
    post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
		expect(user.reload.total_points).to eq(User::Points::REPORT_SUBMITTED)
	end

  #---------------------------------------------------------------------------

  describe "Location model" do
    it "increments Location" do
      expect {
        post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
      }.to change(Location, :count).by(1)
    end

    it "saves the 'address' attribute of Location" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params

      l = Location.last
      expect(l.address).to eq(location_hash[:address])
    end

    it "adds latitude/longitude" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
      expect(Report.last.location.latitude).to  eq(50.0)
      expect(Report.last.location.longitude).to eq(40.0)
    end

    it "sets neighborhood" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
      expect(Report.last.location.neighborhood_id).to eq(neighborhood.id)
    end

    it "uses an existing Location if address exists" do
      location = FactoryGirl.create(:location, :address => location_hash[:address])

      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params
      expect(Report.last.location_id).to eq(location.id)
    end
  end

	#---------------------------------------------------------------------------

  describe "with Errors" do
    render_views

    it "validates on address" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash.merge(:address => nil), :has_before_photo => 1, :report => report_params
      expect(response.body).to have_content("Dirección es obligatorio")
    end

    it "validates on presence of has_before_photo" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :report => report_params
      expect(response.body).to have_content("You need to specify if the report has a before photo or not!")
    end

    it "validates on missing before photo" do
      post :create, :neighborhood_id => neighborhood.id, :location => location_hash, :has_before_photo => 1, :report => report_params.merge(:compressed_photo => nil)
      expect(response.body).to have_content(I18n.t("activerecord.attributes.report.before_photo") + " " + I18n.t("activerecord.errors.messages.blank"))
    end
  end

end
