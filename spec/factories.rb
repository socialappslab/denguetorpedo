# -*- encoding : utf-8 -*-
require 'rack/test'

FactoryGirl.define do
  factory :organization do
    name "SSI"
  end

	factory :breeding_site do
		description_in_pt "Test"
		description_in_es "Test"

		after(:create) do |site|
			create_list(:elimination_method, 1, :breeding_site_id => site.id)
		end
	end

	factory :city do
		name "San Francisco"
		state "San Francisco"
		state_code "SF"
		time_zone "America/Guatemala"
		country "United States"
	end

	factory :comment
	factory :conversation
	factory :csv_error

	factory :spreadsheet do
		factory :parsed_csv do
			csv Rack::Test::UploadedFile.new('spec/support/nicaragua_csv/N002001003.xlsx', 'text/xlsx')
			parsed_at { Time.zone.now }
			association :location
			association :user
		end
	end

	factory :device_session
	factory :documentation_section

	factory :elimination_method do
		description_in_pt "Eliminated Test"
		description_in_es "Eliminated Test"
		points 10
	end

	factory :inspection
	factory :like
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

	factory :notification

	factory :post do
		content "Hello world"
	end

	factory :neighborhood do
		name "Test neighborhood"
		association :city
	end

	factory :prize_code

	factory :prize do
		prize_name "Prize"
		cost 100
		stock 100
		description "Description"
	end


  factory :report do
    report 			 "Description"
    before_photo Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
		association  :breeding_site
		association  :neighborhood
		verified_at  {Time.zone.now}
		association  :reporter, :factory => :user

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

	factory :team do
		association :neighborhood
	end

	factory :team_membership


	factory :user_notification do
		medium UserNotification::Mediums::WEB
		notified_at { Time.zone.now }

		factory :message_notification do
			notification_type "Message"
		end

		factory :post_notification do
			notification_type "Post"
		end

		factory :comment_notification do
			notification_type "Comment"
		end
	end


	factory :user do |user|
		name 		 { Faker::Name.first_name }
		username { Faker::Internet.user_name.gsub(" ", "").gsub(".", "") }
		password "denguewarrior"
		password_confirmation "denguewarrior"
		role 		 User::Types::RESIDENT
		locale 	 User::Locales::SPANISH
		association :neighborhood

		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new

		factory :coordinator do
			role User::Types::COORDINATOR
		end

    factory :delegator do
			role User::Types::DELEGATE
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

	factory :visit


end
