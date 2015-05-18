# -*- encoding : utf-8 -*-
require 'rack/test'

FactoryGirl.define do
	factory :user do |user|
		first_name 	{ Faker::Name.first_name }
		last_name 	 { Faker::Name.last_name }
		username		 { Faker::Internet.user_name }
		phone_number { Faker::PhoneNumber.phone_number[0..19] }
		password 						 "denguewarrior"
		password_confirmation "denguewarrior"
		role 			 							 User::Types::RESIDENT
		locale User::Locales::SPANISH
		association :neighborhood

		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new

		factory :coordinator do
			role User::Types::COORDINATOR
		end

		factory :sponsor do
			role User::Types::SPONSOR
		end

		factory :verifier do
			role User::Types::VERIFIER
		end

		factory :visitor do
			role User::Types::VISITOR
		end
	end

	factory :like
	factory :comment

	factory :notification

	factory :documentation_section

	factory :prize_code

	factory :device_session

	factory :prize do
		prize_name "Prize"
		cost 100
		stock 100
		description "Description"
	end

	factory :location do
		address 		"Rua Tatajuba 50"
		association :neighborhood
	end

	factory :notice do
		title "Title"
		description "Description"
		summary "Summary"
		location "DT Headquarter"
		date Time.zone.now
	end

	factory :post do
		content "Hello world"
	end

	factory :csv_report

	#-----------------------------------------------------------------------------

	factory :city do
		name "San Francisco"
		state "San Francisco"
		state_code "SF"
		time_zone "America/Guatemala"
		country "United States"
	end

	factory :neighborhood do
		name "Test neighborhood"
		association :city
	end

	factory :elimination_method do
		description_in_pt "Eliminated Test"
		description_in_es "Eliminated Test"
		points 10
	end

	factory :breeding_site do
		description_in_pt "Test"
		description_in_es "Test"

		after(:create) do |site|
			create_list(:elimination_method, 1, :breeding_site_id => site.id)
		end
	end


  factory :report do
    report 			 "Description"
    before_photo Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
		association  :breeding_site
		association  :neighborhood

		factory :positive_report do
			larvae true
		end

		factory :potential_report do
			larvae false
			pupae  false
		end

		factory :negative_report do
			protected true
		end

		factory :full_report do
			created_at Time.zone.now
			association :reporter, :factory => :user
		end
  end

	factory :inspection

	#-----------------------------------------------------------------------------

	factory :visit do
	end

	#-----------------------------------------------------------------------------

	factory :team do
		association :neighborhood
	end

	factory :team_membership do
	end

	factory :conversation do
	end

	factory :user_notification do
	end

end
