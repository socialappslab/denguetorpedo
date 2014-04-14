# encoding: utf-8
require 'spec_helper'

describe UsersController do
	def sponsor_attributes
		{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "lojista", phone_number: "15105421895", house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	end

	def verifier_attributes
		{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "verificador", phone_number: "15105421895", house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	end

	# def visitor_attributes
	# 	{ user: { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, email: Faker::Internet.email, password: "denguewarrior", password_confirmation: "denguewarrior", role: "verificador", phone_number: "0219xxxxxxxx", :carrier => "Test Carrier", :prepaid => true, house_attributes: { name: "Kang", phone_number: Faker::PhoneNumber.phone_number[0..19]}, location: { street_type: "Rua", street_name: "Tatajuba", street_number: "50", neighborhood: "Maré"}}}
	#
	# end

	#-----------------------------------------------------------------------------

	let(:admin) { FactoryGirl.create(:admin) }
	let(:user)  { FactoryGirl.create(:user)  }

	before(:each) do
		cookies[:auth_token] = user.auth_token
	end

	#-----------------------------------------------------------------------------

	describe "Listing all users" do
		before(:each) do
			cookies[:auth_token] = admin.auth_token
		end

		context "as an admin account" do
			it "response should be success" do
				get :index
				expect(response.status).to eq(200)
			end
		end

		context "as a non-admin account" do
			it "denies access to logged-in users" do
				cookies[:auth_token] = user.auth_token

				get :index
				expect(response.status).not_to eq(200)
			end

			it "denies access to logged-out users" do
				cookies[:auth_token] = nil

				get :index
				expect(response.status).not_to eq(200)
			end
		end
	end

	#-----------------------------------------------------------------------------

	describe "Get Special_new" do
		context "when logged in with admin account" do
			before(:each) do
				admin = FactoryGirl.create(:admin)
				controller.stub(:current_user).and_return(admin)
			end
			it "should return success" do
				get :special_new
				response.should
			end
		end

		context "when looged in with other accounts type" do
			before(:each) do
				user = FactoryGirl.create(:user)
				controller.stub(:current_user).and_return(user)
			end

			it "should return failure" do
				get :special_new
				response.should_not be_success
			end
		end
	end

	#-----------------------------------------------------------------------------

	describe "Post Special_create" do
		describe "when logged in with admin account" do
			before(:each) do
				admin = FactoryGirl.create(:admin)
				controller.stub(:current_user).and_return(admin)
			end
			it "should create a sponsor successfully" do
				post :special_create, sponsor_attributes
				response.should be_redirect
			end

			it "should create a verifier successfully" do
				post :special_create, verifier_attributes
				response.should be_redirect
			end

		end

		describe "when logged in with other accounts" do
			before(:each) do
				user = FactoryGirl.create(:user)
				controller.stub(:current_user).and_return(user)
			end
			it "should not create a sponsor" do
				post :special_create, FactoryGirl.attributes_for(:sponsor)
				response.should_not be_success
			end

			it "should not create a verifier" do
				post :special_create, FactoryGirl.attributes_for(:verifier)
				response.should_not be_success
			end

			it "should not create a visitor" do
				post :special_create, FactoryGirl.attributes_for(:visitor)
				response.should_not be_success
			end
		end
	end

	#-----------------------------------------------------------------------------

end
