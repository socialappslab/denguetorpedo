require 'rack/test'

FactoryGirl.define do
	factory :user do |user|
		user.first_name { Faker::Name.first_name }
		user.last_name { Faker::Name.last_name }
		user.email { Faker::Internet.email }
		user.nickname { Faker::Name.first_name }
		user.middle_name { Faker::Name.first_name }
		user.phone_number { Faker::PhoneNumber.phone_number[0..19] }
		user.password "denguewarrior"
		user.password_confirmation "denguewarrior"
		user.carrier "XXX"
		user.prepaid true
		role 			 User::Types::RESIDENT
		# neighborhood_id Neighborhood.first.id

		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new

		factory :coordinator do
			role "coordenador"
		end

		factory :sponsor do
			role "lojista"
		end

		factory :verifier do
			role "verificador"
		end

		factory :visitor do
			role "visitante"
		end
	end

	factory :notification

	factory :documentation_section

	factory :prize_code

	factory :prize do
		prize_name "Prize"
		cost 100
		stock 100
		description "Description"

	end

	factory :house do
		name "Rede Trel"
		association :location
		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new
	end

	factory :location do
		street_type 		"Rua"
		street_name 		"Tatajuba"
		street_number 	"50"
	end

	factory :notice do
		title "Title"
		description "Description"
		summary "Summary"
		location "DT Headquarter"
		date Date.new
	end

	factory :post do
		content "Hello world"
	end

  factory :report do
    report "Description"
    before_photo Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
  end

	factory :team do
	end

	factory :team_membership do
	end

end
