# -*- encoding : utf-8 -*-
require "rails_helper"

describe ReportsController do
	let(:neighborhood) { FactoryGirl.create(:neighborhood) }
	let(:user) 			 { FactoryGirl.create(:user) }
	let(:location)   { FactoryGirl.create(:location) }
	let(:csv_report) { FactoryGirl.create(:csv_report) }
	let(:report)     { FactoryGirl.create(:report, :protected => true, :verified_at => nil, :larvae => false, :pupae => false, :location => location, :reporter => user, :csv_report_id => csv_report.id) }
	let(:report_params) { FactoryGirl.attributes_for(:report).merge(:before_photo => nil, :compressed_photo => base64_image_string)}

  before(:each) do
    cookies[:auth_token] = user.auth_token

		report.before_photo = nil
		report.save
  end

	#-----------------------------------------------------------------------------

	it "sets verified_at" do
		expect(report.verified_at).to eq(nil)
		put :verify_report, :neighborhood_id => neighborhood.id, :id => report.id, :has_before_photo => 1, :report => report_params
		expect(report.reload.verified_at).not_to eq(nil)
	end

	it "allows to save without before photo" do
		report_params.delete(:compressed_photo)
		put :verify_report, :neighborhood_id => neighborhood.id, :id => report.id, :has_before_photo => 0, :report => report_params
		expect(report.reload.verified_at).not_to eq(nil)
	end

	#-----------------------------------------------------------------------------

	describe "Visiting Verification Page" do
		render_views

		it "renders" do
			get :verify, :neighborhood_id => neighborhood.id, :id => report.id
			expect(response.body).not_to eq("")
		end
	end

	#-----------------------------------------------------------------------------

	describe "with Errors" do
		render_views

		it "validates on presence of has_before_photo" do
			put :verify_report, :neighborhood_id => neighborhood.id, :id => report.id, :report => report_params
			expect(response.body).to have_content(I18n.t("views.reports.missing_has_before_photo"))
		end

		it "validates on missing before photo" do
			put :verify_report, :neighborhood_id => neighborhood.id, :id => report.id,  :has_before_photo => 1, :report => report_params.merge(:compressed_photo => nil)
			expect(response.body).to have_content(I18n.t("activerecord.attributes.report.before_photo") + " " + I18n.t("activerecord.errors.messages.blank"))
		end
	end


end
