# -*- encoding : utf-8 -*-
require "rails_helper"

describe ReportsController do
	let(:neighborhood) { FactoryGirl.create(:neighborhood) }
	let(:user) 			 { FactoryGirl.create(:user) }
	let(:location)   { FactoryGirl.create(:location) }
	let(:csv_report) { FactoryGirl.create(:spreadsheet) }
	let(:report_params) { {:compressed_photo => base64_image_string, :elimination_method_id => report.breeding_site.elimination_methods.first.id, "eliminated_at(3i)"=>"9", "eliminated_at(2i)"=>"8", "eliminated_at(1i)"=>"2015" } }
  let(:inspection_time) { Time.parse("2015-01-01 12:00") }
  let(:report) 	 { FactoryGirl.create(:report, :created_at => inspection_time, :verified_at => Time.zone.now, :protected => true, :larvae => false, :pupae => false, :csv_report_id => csv_report.id, :completed_at => inspection_time, :location_id => location.id, :reporter_id => user.id) }

  before(:each) do
    cookies[:auth_token] = user.auth_token
		v = Visit.find_or_create_visit_for_location_id_and_date(report.location_id, report.created_at)
		report.update_inspection_for_visit(v)
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

	it "allows to eliminate even if report doesn't have initial visit" do
		Visit.destroy_all

		put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 1, :report => report_params
		expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-08-09")
	end

	it "sets eliminated_at" do
		put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 1, :report => report_params
		expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-08-09")
	end

	it "awards the eliminating user" do
		before_points = user.total_points
		put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 1, :report => report_params
		expect(user.reload.total_points).to be(before_points + report.breeding_site.elimination_methods.first.points)
	end

	it "allows to eliminate report without after photo" do
    put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil)
		expect(report.reload.eliminated_at.strftime("%Y-%m-%d")).to eq("2015-08-09")
	end

	describe "Visit and inspection instances" do
		before(:each) do
			Visit.find_or_create_visit_for_location_id_and_date(report.location_id, report.created_at)
		end

		it "creates an elimination Visit" do
			expect {
				put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil)
			}.to change(Visit, :count).by(1)
		end

		it "creates an Inspection instance" do
			expect {
				put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil)
			}.to change(Inspection, :count).by(1)
		end

		it "creates an elimination Visit with correct attributes" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil)
			v = Visit.last
			expect(v.visited_at.strftime("%d-%m-%Y")).to eq("09-08-2015")
			expect(v.location_id).to eq(report.location_id)
		end

		it "creates an Inspection with correct attributes" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil)
			v = Inspection.last
			expect(v.identification_type).to eq(Inspection::Types::NEGATIVE)
			expect(v.report_id).to eq(Report.last.id)
		end


		# it "sets visited_at to be at least 1 minute", :after_commit => true do
		# 	t = Time.zone.now
		# 	r = FactoryGirl.create(:full_report, :completed_at => t, :created_at => t, :location => location)
		#
		# 	# r.after_photo 	= Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
		# 	# r.elimination_method_id = 1
		# 	# r.eliminated_at = t
		# 	# r.save!
		#
		# 	put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :has_after_photo => 0, :report => report_params.merge(:compressed_photo => nil, :eliminated_at => t)
		#
		# 	original_visit 	 = r.initial_visit
		# 	subsequent_visit = Visit.where("parent_visit_id IS NOT NULL").first
		# 	expect(original_visit.visited_at).to eq(t)
		# 	expect(subsequent_visit.visited_at).to eq(t + Report::ELIMINATION_THRESHOLD)
		# end

	end

  #-----------------------------------------------------------------------------

  describe "with Errors" do
		render_views

		it "validates on presence of has_after_photo" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id, :report => report_params
			expect(response.body).to have_content("Es necesario especificar si el informe tiene una después de la foto o no!")
		end

		it "validates on missing after photo" do
			put :eliminate, :neighborhood_id => neighborhood.id, :id => report.id,  :has_after_photo => 1, :report => report_params.merge(:compressed_photo => nil)
			expect(response.body).to have_content(I18n.t("activerecord.attributes.report.after_photo") + " " + I18n.t("activerecord.errors.messages.blank"))
		end
	end

  #-----------------------------------------------------------------------------

end
