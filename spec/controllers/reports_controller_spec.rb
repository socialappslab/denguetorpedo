# encoding: utf-8
require 'spec_helper'

describe ReportsController do
	#-----------------------------------------------------------------------------

	describe "Getting a list of reports" do
		it "return a list of reports" do
			get :index
		end
	end

	#-----------------------------------------------------------------------------

	describe "Creating a new report" do
		let!(:user) { FactoryGirl.create(:user) }

		before(:each) do
			cookies[:auth_token] = user.auth_token
		end

		it "is only allowed for logged in users" do
			cookies[:auth_token] = nil
			post :create
			expect(flash[:alert]).to eq("Faça o seu login para visualizar essa página.")
		end

		describe "successfully" do
			let(:user)         		 { FactoryGirl.create(:user) }
			let(:street_hash)  		 { {:street_type => "Rua", :street_name => "Darci Vargas", :street_number => "45"} }
			let(:before_photo_file) { File.open("spec/support/foco_marcado.jpg") }
			let(:uploaded_before_photo) { ActionDispatch::Http::UploadedFile.new(:tempfile => before_photo_file, :filename => File.basename(before_photo_file)) }

			before(:each) do
				cookies[:auth_token] = user.auth_token
			end

			it "creates a report if no map coordinates are present" do
			end

			it "finds map coordinates even if user didn't submit them" do
				location = Location.find_by_street_type_and_street_number(street_hash[:street_type], street_hash[:street_number])
				expect(location).to  eq(nil)

				post :create, street_hash.merge(:report => { :report => "Testing", :before_photo => uploaded_before_photo })

				location = Location.find_by_street_type_and_street_number(street_hash[:street_type], street_hash[:street_number])
				expect(location.latitude).to  eq(680555.9952487927)
				expect(location.longitude).to eq(7471957.144050697)
			end
		end

	end

	#-----------------------------------------------------------------------------

	describe "Deleting reports" do
		let(:report) { FactoryGirl.create(:report) }

		it "should deduct points" do
			delete :destroy, id: report.id
			response.should be_redirect
		end
	end

	#-----------------------------------------------------------------------------
end
