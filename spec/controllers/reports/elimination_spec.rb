# -*- encoding : utf-8 -*-
require "rails_helper"

describe ReportsController do
	let(:neighborhood) { FactoryGirl.create(:neighborhood) }
	let(:user) 			 { FactoryGirl.create(:user) }
	let(:location)   { FactoryGirl.create(:location) }
	let(:csv_report) { FactoryGirl.create(:csv_report) }
	let(:report_params) { {:compressed_photo => base64_image_string, :elimination_method_id => report.breeding_site.elimination_methods.first.id, "eliminated_at(3i)"=>"9", "eliminated_at(2i)"=>"8", "eliminated_at(1i)"=>"2015" } }
  let(:inspection_time) { Time.parse("2015-01-01 12:00") }
  let(:report) 	 { FactoryGirl.create(:report, :created_at => inspection_time, :verified_at => Time.zone.now, :protected => true, :larvae => false, :pupae => false, :csv_report_id => csv_report.id, :completed_at => inspection_time, :location_id => location.id, :reporter_id => user.id) }

  before(:each) do
    cookies[:auth_token] = user.auth_token
  end

	#-----------------------------------------------------------------------------

	describe "Visiting Elimination Page" do
		render_views

		it "renders" do
			get :edit, :neighborhood_id => neighborhood.id, :id => report.id
			expect(response.body).not_to eq("")
		end
	end

	#-----------------------------------------------------------------------------

	it "sets eliminated_at" do
		put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_before_photo => 1, :report => report_params
		expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-08-09")
	end

	it "awards the eliminating user" do
		before_points = user.total_points
		put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_before_photo => 1, :report => report_params
		expect(user.reload.total_points).to eq(before_points + report.breeding_site.elimination_methods.first.points)
	end

  #-----------------------------------------------------------------------------

  describe "with Errors" do
		render_views

		it "validates on presence of has_before_photo" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :report => report_params
			expect(response.body).to have_content("You need to specify if the report has a before photo or not!")
		end

		it "validates on missing after photo" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id,  :has_before_photo => 1, :report => report_params.merge(:compressed_photo => nil)
			expect(response.body).to have_content(I18n.t("activerecord.attributes.report.after_photo") + " " + I18n.t("activerecord.errors.messages.blank"))
		end
	end

  #-----------------------------------------------------------------------------

end
