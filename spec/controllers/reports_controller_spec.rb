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

		it "returns an error if no x or y coordinates are given" do
			post :create
			expect(flash[:alert]).to eq("Você precisa marcar uma localização válida para o seu foco.")
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
